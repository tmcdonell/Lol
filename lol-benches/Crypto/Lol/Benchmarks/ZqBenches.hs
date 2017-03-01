{-|
Module      : Crypto.Lol.Benchmarks.ZqBenches
Description : Benchmarks for modular arithmetic.
Copyright   : (c) Eric Crockett, 2011-2017
                  Chris Peikert, 2011-2017
License     : GPL-2
Maintainer  : ecrockett0@email.com
Stability   : experimental
Portability : POSIX

Benchmarks for modular arithmetic.
-}

{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoImplicitPrelude     #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE TypeFamilies          #-}

module Crypto.Lol.Benchmarks.ZqBenches (zqBenches) where

import Crypto.Lol

import Control.Applicative
import Control.Monad
import Control.Monad.Random hiding (lift)
import qualified Data.Vector.Unboxed as U
import qualified Data.Array.Repa as R

import Utils
import GenArgs
import Benchmarks

type Arr = R.Array R.U R.DIM1

-- | Benchmarks for 'ZqBasic'
zqBenches :: IO Benchmark
zqBenches = benchGroup "ZqBasic" [
  hideArgs bench_mul_unb (Proxy::Proxy (Zq 577)),
  hideArgs bench_mul_repa (Proxy::Proxy (Zq 577))
  ]

bench_mul_repa :: (Ring zq, U.Unbox zq) => Arr zq -> Arr zq -> Bench zq
bench_mul_repa a = bench (R.computeUnboxedS . R.zipWith (*) a)

bench_mul_unb :: (Ring zq, U.Unbox zq) => U.Vector zq -> U.Vector zq -> Bench zq
bench_mul_unb a = bench (U.zipWith (*) a)

vecLen :: Int
vecLen = 100

instance (U.Unbox zq, Random zq, MonadRandom rnd) => Generatable rnd (Arr zq) where
  genArg = R.fromListUnboxed (R.Z R.:. vecLen) <$> replicateM vecLen getRandom

instance (U.Unbox zq, Random zq, MonadRandom rnd) => Generatable rnd (U.Vector zq) where
  genArg = U.fromList <$> replicateM vecLen getRandom
