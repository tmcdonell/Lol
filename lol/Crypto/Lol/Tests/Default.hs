{-|
Module      : Crypto.Lol.Tests.Default
Description : High-level tensor tests.
Copyright   : (c) Eric Crockett, 2011-2017
                  Chris Peikert, 2011-2017
License     : GPL-3
Maintainer  : ecrockett0@email.com
Stability   : experimental
Portability : POSIX

High-level test groups and parameters,
which can be used to verify a 'Crypto.Lol.Cyclotomic.Tensor' implementation.
-}

{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE PolyKinds             #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE TypeOperators         #-}

{-# OPTIONS_GHC -fno-warn-partial-type-signatures #-}

module Crypto.Lol.Tests.Default (defaultLolTests, defaultZqTests) where

import Crypto.Lol.Factored
import Crypto.Lol.Tests.CycTests
import Crypto.Lol.Tests.TensorTests
import Crypto.Lol.Tests.ZqTests
import Crypto.Lol.Utils.ShowType
import Crypto.Lol.Types.IrreducibleChar2 ()

import Data.Proxy
import Test.Framework

-- | Default parameters for 'Crypto.Lol.Types.Unsafe.ZqBasic' tests.
defaultZqTests :: Test
defaultZqTests = testGroup "Zq Tests" $ [
  zqTests (Proxy::Proxy (Zq 3)),
  zqTests (Proxy::Proxy (Zq 7)),
  zqTests (Proxy::Proxy (Zq (3 ** 5))),
  zqTests (Proxy::Proxy (Zq (3 ** 5 ** 7)))]

-- | Default @m@/@r@ test parameters, for an arbitrary 'Crypto.Lol.Cyclotomic.Tensor'.
defaultLolTests :: _ => Proxy t -> [Test]
defaultLolTests pt = [
  testGroup "Tensor Tests" $ ($ pt) <$> [
    tensorTests1 (Proxy::Proxy '(F7,  Zq 29)),
    tensorTests1 (Proxy::Proxy '(F12, SmoothZQ1)),
    tensorTests1 (Proxy::Proxy '(F1,  Zq 17)),
    tensorTests1 (Proxy::Proxy '(F2,  Zq 17)),
    tensorTests1 (Proxy::Proxy '(F4,  Zq 17)),
    tensorTests1 (Proxy::Proxy '(F8,  Zq 17)),
    tensorTests1 (Proxy::Proxy '(F21, Zq 8191)),
    tensorTests1 (Proxy::Proxy '(F42, Zq 8191)),
    tensorTests1 (Proxy::Proxy '(F42, ZQ1)),
    tensorTests1 (Proxy::Proxy '(F2,  ZQ2)),
    tensorTests1 (Proxy::Proxy '(F3,  ZQ2)),
    tensorTests1 (Proxy::Proxy '(F7,  ZQ2)),
    tensorTests1 (Proxy::Proxy '(F6,  ZQ2)),
    tensorTests1 (Proxy::Proxy '(F42, SmoothZQ3)),
    tensorTests1 (Proxy::Proxy '(F42, ZQ2)),
    tensorTests1 (Proxy::Proxy '(F89, Zq 179)),

    tensorTests2 (Proxy::Proxy '(F1, F7,  Zq 29)),
    tensorTests2 (Proxy::Proxy '(F4, F12, Zq 536871001)),
    tensorTests2 (Proxy::Proxy '(F4, F12, SmoothZQ1)),
    tensorTests2 (Proxy::Proxy '(F2, F8,  Zq 17)),
    tensorTests2 (Proxy::Proxy '(F8, F8,  Zq 17)),
    tensorTests2 (Proxy::Proxy '(F2, F8,  SmoothZQ1)),
    tensorTests2 (Proxy::Proxy '(F4, F8,  Zq 17)),
    tensorTests2 (Proxy::Proxy '(F3, F21, Zq 8191)),
    tensorTests2 (Proxy::Proxy '(F7, F21, Zq 8191)),
    tensorTests2 (Proxy::Proxy '(F3, F42, Zq 8191)),
    tensorTests2 (Proxy::Proxy '(F3, F21, ZQ1)),
    tensorTests2 (Proxy::Proxy '(F7, F21, ZQ2)),
    tensorTests2 (Proxy::Proxy '(F3, F42, ZQ3))],

  testGroup "Cyc Tests" $ ($ pt) <$> [
    cycTests1    (Proxy::Proxy '(F7,  Zq 29)),
    cycTests1    (Proxy::Proxy '(F7,  Zq 32)),
    cycTests1    (Proxy::Proxy '(F12, SmoothZQ1)),
    cycTests1    (Proxy::Proxy '(F1,  Zq 17)),
    cycTests1    (Proxy::Proxy '(F2,  Zq 17)),
    cycTests1    (Proxy::Proxy '(F4,  Zq 17)),
    cycTests1    (Proxy::Proxy '(F8,  Zq 17)),
    cycTests1    (Proxy::Proxy '(F21, Zq 8191)),
    cycTests1    (Proxy::Proxy '(F42, Zq 8191)),
    cycTests1    (Proxy::Proxy '(F42, ZQ1)),
    cycTests1    (Proxy::Proxy '(F42, Zq 1024)),
    cycTests1    (Proxy::Proxy '(F42, ZQ2)),
    cycTests1    (Proxy::Proxy '(F89, Zq 179)),

    cycTests2    (Proxy::Proxy '(F1, F7, Zq PP8)),
    cycTests2    (Proxy::Proxy '(F1, F7, Zq PP2))]]

-- three 24-bit moduli, enough to handle rounding for p=32 (depth-4 circuit at ~17 bits per mul)
type ZQ1 = Zq 18869761
type ZQ2 = Zq (19393921 ** 18869761)
type ZQ3 = Zq (19918081 ** 19393921 ** 18869761)

type SmoothZQ1 = Zq 2148249601
type SmoothZQ3 = Zq (2148854401 ** 2148249601 ** 2150668801)