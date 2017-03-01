{-|
Module      : TestLolRepaMain
Description : Main driver for lol tests with RT.
Copyright   : (c) Eric Crockett, 2011-2017
                  Chris Peikert, 2011-2017
License     : GPL-2
Maintainer  : ecrockett0@email.com
Stability   : experimental
Portability : POSIX

Main driver for lol tests with RT.
-}

module TestLolRepaMain where

import Crypto.Lol.Cyclotomic.Tensor.Repa
import Crypto.Lol.Tests.Standard
import Data.Proxy

main :: IO ()
main = defaultTestMain (Proxy::Proxy RT)