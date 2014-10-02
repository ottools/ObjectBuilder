////////////////////////////////////////////////////////////////////////////////
//
//  Licensed to the Apache Software Foundation (ASF) under one or more
//  contributor license agreements.  See the NOTICE file distributed with
//  this work for additional information regarding copyright ownership.
//  The ASF licenses this file to You under the Apache License, Version 2.0
//  (the "License"); you may not use this file except in compliance with
//  the License.  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
////////////////////////////////////////////////////////////////////////////////

package otlib.events
{
    import flash.events.Event;
    
    public class StorageEvent extends Event
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        public var changedIds:Vector.<uint>;
        public var category:String;
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function StorageEvent(type:String,
                                     bubbles:Boolean = false,
                                     cancelable:Boolean = false,
                                     changedIds:Vector.<uint> = null,
                                     category:String = null)
        {
            super(type, bubbles, cancelable);
            
            this.changedIds = changedIds;
            this.category = category;
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Override Public
        //--------------------------------------
        
        override public function clone():Event
        {
            return new StorageEvent(this.type, this.bubbles, this.cancelable, this.changedIds, this.category);
        }
        
        //--------------------------------------------------------------------------
        // STATIC
        //--------------------------------------------------------------------------
        
        public static const LOAD:String = "load";
        public static const CHANGE:String = "change";
        public static const COMPILE:String = "compile";
        public static const UNLOADING:String = "unloading";
        public static const UNLOAD:String = "unload";
    }
}
