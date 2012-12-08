iPhone Auto-Translate
=====================

With this little utility, you can localise your iPhone app by using Microsoft Translator. It's a bit tongue in cheek, but might be useful if you're an indie developer with no budget for professional translations, especially if your app doesn't use all that much text. Anyway, i hope someone finds it useful!

You can set it up as a script you run on your build server that localises any new strings as they get added to the project.

Setup
-----

You must first edit a couple of settings at the top of the following .m files before this will work:

* AzureAccessToken.m - You must enter your Microsoft Azure client id and client secret.
* AutoTranslate.m - Edit the source folders and original language if you need.

Blog
----

You can read more about this project and how to use it at my blog here:

[http://www.splinter.com.au/2012/12/08/iphone-auto-translate/](http://www.splinter.com.au/2012/12/08/iphone-auto-translate/)

MIT License
-------

Copyright (C) 2012 Chris Hulbert.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
