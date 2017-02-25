{-|
Module      : AllMain
Description : Pulls in all modules.
Copyright   : (c) Eric Crockett, 2011-2017
                  Chris Peikert, 2011-2017
License     : GPL-2
Maintainer  : ecrockett0@email.com
Stability   : experimental
Portability : POSIX

This module depends on all source code modules, so it is useful for checking
that all code compiles, including all top-level executables.
-}

import SHEMain ()
import KHPRFMain ()
import HomomPRFMain ()
import TestAppsMain ()
import BenchAppsMain ()
import LolTestsMain ()

-- EAC: This doesn't compile because RRq is missing a CRTrans instance, or at
-- least a definition of CRTIndex. Can we define a CRTrans instance? If not,
-- can we disassociate CRTIndex from the class and still get rlwe-challenges to compile?
--import RLWEChallengesMain ()

import BenchCPPMain ()
import TestCPPMain ()

import BenchRepaMain ()
import TestRepaMain ()
