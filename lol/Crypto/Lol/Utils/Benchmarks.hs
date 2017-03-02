{-|
Module      : Crypto.Lol.Utils.Benchmarks
Description : Infrastructure for benchmarking Lol.
Copyright   : (c) Eric Crockett, 2011-2017
                  Chris Peikert, 2011-2017
License     : GPL-3
Maintainer  : ecrockett0@email.com
Stability   : experimental
Portability : POSIX

Infrastructure for benchmarking Lol.
-}

{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE GADTs                 #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PolyKinds             #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeFamilies          #-}

module Crypto.Lol.Utils.Benchmarks
(Crypto.Lol.Utils.Benchmarks.bench
,benchM
,benchIO
,benchGroup
,genBenchArgs
,Bench
,Benchmark
,addGen) where

import Control.DeepSeq
import Control.Monad.Random
import Criterion as C
import Crypto.Lol.Utils.GenArgs
import Data.Proxy

-- | Convenience function for benchmarks with an extra parameter.
addGen :: Proxy gen -> Proxy '(t,m,r) -> Proxy '(t,m,r,gen)
addGen _ _ = Proxy

-- | Wrapper for criterion's 'nf'.
{-# INLINABLE bench #-}
bench :: NFData b => (a -> b) -> a -> Bench params
bench f = Bench . nf f

-- | Use when you need randomness /outside/ the benchmark.
benchM :: (forall m . (MonadRandom m) => m (Bench a)) -> Bench a
benchM = BenchM

-- | Wrapper for criterion's 'nfIO'. Use when there is randomness /inside/ the
-- benchmark.
benchIO :: NFData b => IO b -> Bench params
benchIO = Bench . nfIO

{-# INLINABLE benchGroup #-}
-- | Wrapper for criterion's 'bgroup'.
benchGroup :: (Monad rnd) => String -> [rnd Benchmark] -> rnd Benchmark
benchGroup str = (bgroup str <$>) . sequence

-- | Converts a function mapping zero or more arguments to a 'Bench' @a@
-- by generating random inputs to the function.
genBenchArgs :: (GenArgs bnch, ResultOf bnch ~ Bench a, MonadRandom rnd)
  => String -> bnch -> Proxy a -> rnd Benchmark
genBenchArgs s f _ = (C.bench s . unbench) <$> genArgs f

unbench :: Bench a -> Benchmarkable
unbench (Bench x) = x
unbench (BenchM _) = error "cannot unbench BenchM"

-- | Wrapper around criterion's 'Benchmarkable', with phantom parameters.
data Bench params where
  Bench :: Benchmarkable -> Bench a
  BenchM :: (forall m . (MonadRandom m) => m (Bench a)) -> Bench a

instance GenArgs (Bench params) where
  genArgs x@(Bench _) = return x
  genArgs (BenchM x) = x
