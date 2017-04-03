/*
*  Copyright (c) 2014-2017 Object Builder <https://github.com/ottools/ObjectBuilder>
*
*  Permission is hereby granted, free of charge, to any person obtaining a copy
*  of this software and associated documentation files (the "Software"), to deal
*  in the Software without restriction, including without limitation the rights
*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*  copies of the Software, and to permit persons to whom the Software is
*  furnished to do so, subject to the following conditions:
*
*  The above copyright notice and this permission notice shall be included in
*  all copies or substantial portions of the Software.
*
*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
*  THE SOFTWARE.
*/

package nail.commands
{
    import flash.desktop.NativeApplication;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.system.MessageChannel;
    import flash.system.Worker;
    import flash.system.WorkerDomain;
    import flash.system.WorkerState;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.getQualifiedClassName;
    import flash.utils.getQualifiedSuperclassName;

    import nail.errors.NullArgumentError;
    import nail.errors.SingletonClassError;
    import nail.logging.Log;
    import nail.signals.Signal;
    import nail.utils.isNullOrEmpty;

    public class Communicator extends EventDispatcher implements ICommunicator
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------

        private var m_worker:Worker;
        private var m_inputChannel:MessageChannel;
        private var m_outputChannel:MessageChannel;
        private var m_callbacks:Dictionary;
        private var m_background:Boolean;
        private var m_descriptor:XML;

        //--------------------------------------
        // Getters / Setters
        //--------------------------------------

        public function get worker():Worker { return m_worker; }
        public function get running():Boolean { return (m_worker.state == WorkerState.RUNNING); }
        public function get background():Boolean { return m_background; }
        public function get applicationDescriptor():XML { return m_descriptor; }

        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------

        public function Communicator(workerBytesClass:ByteArray = null)
        {
            if (s_instance)
                throw new SingletonClassError(Communicator);

            s_instance = this;

            m_callbacks = new Dictionary();
            m_descriptor = NativeApplication.nativeApplication.applicationDescriptor;

            if (workerBytesClass)
            {
                m_worker = WorkerDomain.current.createWorker(workerBytesClass, true);
                m_worker.addEventListener(Event.WORKER_STATE, workerStateHandler);
                m_outputChannel = Worker.current.createMessageChannel(m_worker);
                m_worker.setSharedProperty("outputChannel", m_outputChannel);

                m_inputChannel = m_worker.createMessageChannel(Worker.current);
                m_inputChannel.addEventListener(Event.CHANNEL_MESSAGE, inputChannelHandler);
                m_worker.setSharedProperty("inputChannel", m_inputChannel);

                m_background = false;
            }
            else
            {
                m_worker = Worker.current;
                m_worker.addEventListener(Event.WORKER_STATE, workerStateHandler);
                m_inputChannel = MessageChannel( m_worker.getSharedProperty("outputChannel") );
                m_inputChannel.addEventListener(Event.CHANNEL_MESSAGE, inputChannelHandler);

                m_outputChannel = MessageChannel( m_worker.getSharedProperty("inputChannel") );

                m_background = true;

                registerCallback(ApplicationDescriptorCommand, onApplicationDescriptor);
            }
        }

        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------

        //--------------------------------------
        // Public
        //--------------------------------------

        public function registerCallback(commandClass:Class, callback:Function):void
        {
            if (commandClass == null)
                throw new NullArgumentError("commandClass");

            if (getQualifiedSuperclassName(commandClass) != "nail.commands::Command")
                throw new ArgumentError("The argument commandClass is not a Command class.");

            if (callback == null)
                throw new NullArgumentError("callback");

            var type:String = getQualifiedClassName(commandClass);
            var signal:Signal;

            if (m_callbacks[type] == undefined)
            {
                signal = new Signal();
                m_callbacks[type] = signal;
            }
            else
            {
                signal = m_callbacks[type];

                if (signal.hasCallback(callback))
                    throw new Error("Attempt to register a method already registered.");
            }

            signal.addCallback(callback);
        }

        public function unregisterCallback(commandClass:Class, callback:Function):void
        {
            if (commandClass == null)
                throw new NullArgumentError("commandClass");

            if (callback == null)
                throw new NullArgumentError("callback");

            var type:String = getQualifiedClassName(commandClass);

            if (m_callbacks[type] != undefined)
            {
                var signal:Signal = m_callbacks[type];
                signal.removeCallback(callback);

                if (signal.length == 0)
                    delete m_callbacks[type];
            }
        }

        public function sendCommand(command:Command):void
        {
            if (!command)
                throw new NullArgumentError("command");

            if (!background && command is LogCommand)
                parseLog( LogCommand(command) );
            else if (background || running)
                m_outputChannel.send([command.type, command.args]);
        }

        public function start():void
        {
            if (!background && !running)
                m_worker.start();
        }

        //--------------------------------------
        // Private
        //--------------------------------------

        private function parseLog(command:LogCommand):void
        {
            if (m_callbacks[command.type] != undefined)
                m_callbacks[command.type].dispatch(command.args);
            else
            {
                var message:String = command.args[2];
                if (isNullOrEmpty(message))
                    message = command.args[1];

                throw new Error(message);
            }
        }

        //--------------------------------------
        // Private
        //--------------------------------------

        private function onApplicationDescriptor(xml:XML):void
        {
            if (!xml)
                throw new NullArgumentError("xml");

            m_descriptor = xml;
        }

        //--------------------------------------
        // Event Handlers
        //--------------------------------------

        protected function workerStateHandler(event:Event):void
        {
            if (!background && m_worker.state == WorkerState.RUNNING)
            {
                sendCommand(new ApplicationDescriptorCommand(m_descriptor));
            }
        }

        protected function inputChannelHandler(event:Event):void
        {
            if (m_inputChannel.messageAvailable)
            {
                try
                {
                    var message:Array = m_inputChannel.receive() as Array;
                    var type:String = message[0] as String;

                    if (m_callbacks[type] != undefined)
                    {
                        var args:Array = message[1] as Array;
                        var signal:Signal = m_callbacks[type];
                        signal.dispatch(args);
                    }
                    else
                        throw new Error("No listener registered for the type: " + type);
                }
                catch(error:Error)
                {
                    Log.error(error.message, error.getStackTrace(), error.errorID);
                }
            }
        }

        //--------------------------------------------------------------------------
        // STATIC
        //--------------------------------------------------------------------------

        private static var s_instance:ICommunicator;
        public static function getInstance():ICommunicator
        {
            return s_instance;
        }
    }
}
