Sebastian Arcila-Valenzuela's emacs setup
=========================================

This is my emacs setup. It's my effort to build a fresh dot-emacs. I have taken some bits from @febuiles and others.

Compiling emacs for OS X
========================

Note: This works for GNU Emacs 24.3.50.1 (x86_64-apple-darwin12.3.0,
NS apple-appkit-1187.37) on 2013-03-25.

The idea was heavily inspired by a
[serie of posts](http://devblog.avdi.org/category/emacs-reboot/page/2/)
from @avdi's blog, that were on my reading list for so long.

The first step is to download it!

	$ ﻿bzr branch bzr://bzr.savannah.gnu.org/emacs/trunk emacs

Then you need to run the `autogen.sh` and the `configure` scripts

	cd emacs
	./autogen.sh
	./configure --with-ns`

Note: The `--with-ns` flag is to use NeXTstep (Cocoa or GNUstep) windowing system

Almost done!.
You need to run `make install` instead of just `make`, to force the
creation of the *.app, once you are done with the `make` you will be
available to drag and drop the `nextstep/Emacs.app` folder to any
desired install location.

That's all!

Cool Thinks of Emacs 24
=======================
Note: The last version that I were using of Emacs was the 22, looks
like a lot changed.

It has a lot of batteries included

* Ido mode, yes!, you just need to add `(require 'ido)` and `(ido-mode
t)` to your init file.
* Some themes, for example `(load-theme 'wombat)`.
* Package, you don't need to install anything to start using the ELPA.
* Electric modes, I'm using the electric-indent-mode and the electric-pair-mode.
* And probably more, but for now  are the included things that I'm
using.
* Ahh, I also forgot that since I installed Mountain Lion. I got
  some weird behavior with the emacs window system, that don't allow
  me to tab between applications back and forth as usual. This problem
  was completely solved with the compilated version of emacs 24. The
  emacs 22 that I used was Carbon Emacs if I'm not wrong.
