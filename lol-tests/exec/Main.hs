
import Crypto.Lol.Tests.Standard
import Crypto.Lol.Types
import Data.Proxy

import Test.Framework
import System.Environment

main :: IO ()
main = do
  argv <- getArgs
  defaultMainWithArgs
    [zqTs]
    ("--threads=1" : "--maximum-generated-tests=100" : argv)

