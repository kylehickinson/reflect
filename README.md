# Reflect

Reflect is a service that uses Bonjour discovery to allow you to send file data from your Mac to iOS devices.
Reflect lives in your menu bar, and allows you to simply drag files into it to reflect it to one or many clients.

![Reflect Server](http://f.cl.ly/items/1n2x2j0s3Z3c0x0q263i/Screen%20Shot%202012-11-03%20at%2010.38.34%20AM.png)

Don't have Xcode? Don't wanna build it?
→ The server by its lonely self can be downloaded directly [here](http://cl.ly/KcNy).

I'm hoping that if I can get the image reflect client (included in this repo) done in the next couple weeks I can release it in the App Store as a free product.

**Why**

Two weeks ago, I began writing this on my time off to reimplement the functionality of sending an image to my iPhone/iPad for design purposes.  After I got to the point where the server component was complete, I realized this would be an awesome open source project to distribute, but instead of just images, any data could be communicated.  This could even be modified to send data between two Macs or two iOS devices.  Hopefully someone finds this helpful and or builds clients for it.

**What I learned**

After watching some WWDC12 videos on bonjour network programming, all they kept saying is "networking is hard".  They were right.  It took a couple tries to get it working correctly but I'm glad I did because it was a great learning experience.  I'm fairly certain I probably did things wrong in this, so hopefully if you spot something wrong, you'll send a pull-request or open an issue discussing the matter.

## What's Missing

There are a couple things missing, and hopefully I can get them done over the course of the weeks (I only work on this during the weekend).  If you want to take it on to do it yourselves I implore that!  Just send a pull request and I'll be sure to pull it through.  I just ask you keep my OCD at rest and keep to the programming style I've used so far throughout the project.

**Icons**
Since I didn't have a ton of time to do so, the state of icons in this project is pretty sad.  The Mac app icon has no icon,
the menu bar item has some temporary icons I made that shows no obvious state of whats going on.

**Error Handling**
I got a lot of stuff that could go wrong in the networking part handled internally, but right now there's no interface that shows you errors.

**File Type Limiting**
I'd like for you to choose in the preferences what your file types your Reflect server will accept.  Although, yes, you could just not do anything with the data on the client if you get some other file type, it's far better to not send data at all if you can help it.

## Image Reflect Client

![Client](http://f.cl.ly/items/0a183M3v3x1X340E1P1u/iOS%20Simulator%20Screen%20shot%202012-11-03%2010.40.54%20AM.png)

I've included what I set out to build in the first place: An image reflect client.  **It is still incomplete** though.
I will be hopefully working on it some more in the next few weeks to add in the missing features:

* Passcode Support
* Allow choosing of different Reflect servers if there are more then one running on your Wi-Fi network.
* Extension of above: disconnecting from the server to choose another one.
* Allow zooming the image (which I thought I implemented but didn't work).

It also should be known that a lot, and I mean *a lot* of error handling needs to be added to it.
Don't be afraid to jump in and help!

## Building your own client

Since the Reflect server can transfer any data you want, this opens possibilities for clients to be made for all types of data like text, images, HTML, icons, etc.  The Reflect Client project in this repo shows you how to communicate with the server through the packets that are sent.  Packet header definitions as well as packet header documentation is located in *RFPacketHeaders.h* in the server component.  This file is shared with the client via user header searching.

## Requirements

Reflect builds at Mac OS X 10.8+, uses ARC, and also uses objective-C literals. 
The Image Reflect client builds at iOS 6, but also uses ARC and obj-c literals.

It is recommended you use Xcode 4.5+.

Xcode 4.4 is also available to use, but you will have to define the objective-C literal header yourself ([see here](http://petersteinberger.com/blog/2012/using-subscripting-with-Xcode-4_4-and-iOS-4_3/))

**Building at lower targets:**

If you would like to build at a lower target, you'll have to modify it to your own needs.  For example, the image reflect client uses a font not available before iOS 6.

## Documentation

Most headers are documented with [appledoc](http://gentlebytes.com/appledoc/) in mind.  Though there is no pre-generated documenation prepared for you in the repo, you can easily generate it yourself if you have appledoc installed.  This is an example script you could use for it:

    /usr/local/bin/appledoc         \
    --project-name Reflect          \
    --ignore .m                     \
    --output ./doc                  \
    --exit-threshold 2              \
    --no-repeat-first-par           \
    --keep-undocumented-objects     \
    --keep-undocumented-members     \
    .

Source files are also mostly documented just for my own sake, and I'm sure for others sakes in the future.

## License
In addition to the BSD-2 license below, I ask that you do not publicly distribute the app—be it the server, or included client—as a whole in binary form (e.g. on the App Store).

    Copyright (c) 2012, Kyle Hickinson
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
    OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
