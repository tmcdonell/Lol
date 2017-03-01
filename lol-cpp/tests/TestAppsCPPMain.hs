{-|
Module      : TestAppsCPPMain
Description : Main driver for lol-apps tests with CPP.
Copyright   : (c) Eric Crockett, 2011-2017
                  Chris Peikert, 2011-2017
License     : GPL-2
Maintainer  : ecrockett0@email.com
Stability   : experimental
Portability : POSIX

Main driver for lol-apps tests with CPP.
-}

{-# LANGUAGE CPP #-}

module TestAppsCPPMain where

#ifdef WITH_APPS

import Crypto.Lol (TrivGad)
import Crypto.Lol.Cyclotomic.Tensor.CPP
import Crypto.Lol.Applications.Tests.Standard
import Data.Proxy

import Test.Framework

main :: IO ()
main = do
  flip defaultMainWithArgs ["--threads=1","--maximum-generated-tests=100"] $
    defaultTests (Proxy::Proxy CT) (Proxy::Proxy TrivGad)

#else

main :: IO ()
main = return ()

#endif