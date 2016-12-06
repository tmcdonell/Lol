
import SHEMain ()
import KHPRFMain ()
import HomomPRFMain ()
import TestAppsMain ()
import BenchAppsMain ()

-- EAC: This doesn't compile because RRq is missing a CRTrans instance, or at
-- least a definition of CRTIndex. Can we define a CRTrans instance? If not,
-- can we disassociate CRTIndex from the class and still get rlwe-challenges to compile?
--import RLWEChallengesMain ()

import BenchCPPMain ()
import TestCPPMain ()

import BenchRepaMain ()
import TestRepaMain ()
