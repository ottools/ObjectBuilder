///////////////////////////////////////////////////////////////////////////////////
// 
//  Copyright (c) 2014 Nailson <nailsonnego@gmail.com>
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
///////////////////////////////////////////////////////////////////////////////////

package otlib.resources
{
    import mx.resources.ResourceManager;
    
    import nail.core.nail_internal;
    import nail.errors.AbstractClassError;
    import nail.utils.isNullOrEmpty;
    import nail.workers.ApplicationWorker;
    
    use namespace nail_internal;
    
    public final class Resources
    {
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function Resources()
        {
            throw new AbstractClassError(Resources);
        }
        
        //--------------------------------------------------------------------------
        // STATIC
        //--------------------------------------------------------------------------
        
        public static var bundleName:String = "strings";
        
        public static function getString(resourceName:String, ...rest):String
        {
            var locale:String;
            
            if (ApplicationWorker.isRunning)
            {
                locale = ApplicationWorker.instance.getSharedProperty("locale") as String;
                
                if (isNullOrEmpty(locale))
                    locale = "en_US";
            }
            
            return ResourceManager.getInstance().getString(bundleName, resourceName, rest, locale);
        }
    }
}
