{-|
Module      : Crypto.Lol.Benchmarks.TensorBenches
Description : Benchmarks for the 'Tensor' interface.
Copyright   : (c) Eric Crockett, 2011-2017
                  Chris Peikert, 2011-2017
License     : GPL-3
Maintainer  : ecrockett0@email.com
Stability   : experimental
Portability : POSIX

Benchmarks for the 'Tensor' interface. In a perfect world, these benchmarks would
have the same performance as the 'Cyc' benchmarks. In practice, GHC gets in the
way at higher levels of the library, resulting in worse performance for 'Cyc'
in some cases.
-}

{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE NoImplicitPrelude     #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeFamilies          #-}

{-# OPTIONS_GHC -fno-warn-partial-type-signatures #-}

module Crypto.Lol.Benchmarks.TensorBenches (tensorBenches1, tensorBenches2) where

import Control.Applicative
import Control.Monad.Random hiding (lift)

import Crypto.Lol.Utils.Benchmarks
import Crypto.Lol.Prelude
import Crypto.Lol.Cyclotomic.Tensor
import Crypto.Lol.Types
import Crypto.Random

-- | Benchmarks for single-index 'Tensor' operations.
-- There must be a CRT basis for \(O_m\) over @r@.
-- These cover the same functions as @cycBenches1@, but may have different
-- performance due to how GHC interacts with Lol.
{-# INLINABLE tensorBenches1 #-}
tensorBenches1 :: (Monad rnd, _) => Proxy '(t,m,r) -> Proxy gen -> rnd Benchmark
tensorBenches1 ptmr pgen = benchGroup "Tensor" $ ($ ptmr) <$> [
  genBenchArgs "unzipPow" bench_unzip,
  genBenchArgs "unzipDec" bench_unzip,
  genBenchArgs "unzipCRT" bench_unzip,
  genBenchArgs "zipWith (*)" bench_mul,
  genBenchArgs "crt" bench_crt,
  genBenchArgs "crtInv" bench_crtInv,
  genBenchArgs "l" bench_l,
  genBenchArgs "lInv" bench_lInv,
  genBenchArgs "*g Pow" bench_mulgPow,
  genBenchArgs "*g Dec" bench_mulgDec,
  genBenchArgs "*g CRT" bench_mulgCRT,
  genBenchArgs "divg Pow" bench_divgPow,
  genBenchArgs "divg Dec" bench_divgDec,
  genBenchArgs "divg CRT" bench_divgCRT,
  genBenchArgs "lift" bench_liftPow,
  genBenchArgs "error" (bench_errRounded 0.1) . addGen pgen
  ]

-- | Benchmarks for inter-ring 'Tensor' operations.
-- There must be a CRT basis for \(O_{m'}\) over @r@.
-- These cover the same functions as @cycBenches1@, but may have different
-- performance due to how GHC interacts with Lol.
{-# INLINABLE tensorBenches2 #-}
tensorBenches2 :: (Monad rnd, _) => Proxy '(t,m,m',r) -> rnd Benchmark
tensorBenches2 p = benchGroup "Tensor" $ ($ p) <$> [
  genBenchArgs "twacePow" bench_twacePow,
  genBenchArgs "twaceDec" bench_twacePow, -- yes, twacePow is correct here. It's the same function!
  genBenchArgs "twaceCRT" bench_twaceCRT,
  genBenchArgs "embedPow" bench_embedPow,
  genBenchArgs "embedDec" bench_embedDec,
  genBenchArgs "embedCRT" bench_embedCRT
  ]

{-# INLINABLE bench_unzip #-}
bench_unzip :: _ => t m (r,r) -> Bench '(t,m,r)
bench_unzip = bench unzipT

{-# INLINABLE bench_mul #-}
-- no CRT conversion, just coefficient-wise multiplication
bench_mul :: forall t m r . _ => t m r -> t m r -> Bench '(t,m,r)
bench_mul a = bench (zipWithT (*) a :: t m r -> t m r)

{-# INLINABLE bench_crt #-}
-- convert input from Pow basis to CRT basis
bench_crt :: _ => t m r -> Bench '(t,m,r)
bench_crt = bench (fromJust' "TensorBenches.bench_crt" crt)

{-# INLINABLE bench_crtInv #-}
-- convert input from CRT basis to Pow basis
bench_crtInv :: _ => t m r -> Bench '(t,m,r)
bench_crtInv = bench (fromJust' "TensorBenches.bench_crtInv" crtInv)

{-# INLINABLE bench_l #-}
-- convert input from Dec basis to Pow basis
bench_l :: _ => t m r -> Bench '(t,m,r)
bench_l = bench l

{-# INLINABLE bench_lInv #-}
-- convert input from Dec basis to Pow basis
bench_lInv :: _ => t m r -> Bench '(t,m,r)
bench_lInv = bench lInv

{-# INLINABLE bench_liftPow #-}
-- lift an element in the Pow basis
-- EAC: When I elide the constraints, GHC 8.0.112313 says to report a bug.
bench_liftPow :: forall t m r . (LiftOf (TRep t r) ~ TRep t (LiftOf r), _) => t m r -> Bench '(t,m,r)
bench_liftPow = bench (fmapT lift :: t m r -> t m (LiftOf r))

{-# INLINABLE bench_mulgPow #-}
-- multiply by g when input is in Pow basis
bench_mulgPow :: _ => t m r -> Bench '(t,m,r)
bench_mulgPow = bench mulGPow

{-# INLINABLE bench_mulgDec #-}
-- multiply by g when input is in Dec basis
bench_mulgDec :: _ => t m r -> Bench '(t,m,r)
bench_mulgDec = bench mulGDec

{-# INLINABLE bench_mulgCRT #-}
-- multiply by g when input is in CRT basis
bench_mulgCRT :: _ => t m r -> Bench '(t,m,r)
bench_mulgCRT = bench (fromJust' "TensorBenches.bench_mulgCRT" mulGCRT)

{-# INLINABLE bench_divgPow #-}
-- divide by g when input is in Pow basis
bench_divgPow :: _ => t m r -> Bench '(t,m,r)
bench_divgPow = bench divGPow . mulGPow

{-# INLINABLE bench_divgDec #-}
-- divide by g when input is in Dec basis
bench_divgDec :: _ => t m r -> Bench '(t,m,r)
bench_divgDec = bench divGDec . mulGDec

{-# INLINABLE bench_divgCRT #-}
-- divide by g when input is in CRT basis
bench_divgCRT :: _ => t m r -> Bench '(t,m,r)
bench_divgCRT = bench (fromJust' "TensorBenches.bench_divgCRT" divGCRT)

{-# INLINABLE bench_errRounded #-}
-- generate a rounded error term
bench_errRounded :: forall t m r gen . (TElt t r, Fact m, CryptoRandomGen gen, _)
  => Double -> Bench '(t,m,r,gen)
bench_errRounded v = benchIO $ do
  gen <- newGenIO
  return $ evalRand
    (fmapT (roundMult one) <$>
      (tGaussianDec v :: Rand (CryptoRand gen) (t m Double)) :: Rand (CryptoRand gen) (t m (LiftOf r))) gen

-- EAC: due to GHC bug #12634, I have to give these a little more help than the corresponding functions
-- in UCyc and Cyc benches. Not a huge deal.
{-# INLINABLE bench_twacePow #-}
bench_twacePow :: forall t m m' r . (Tensor t, TElt t r, Fact m, _)
  => t m' r -> Bench '(t,m,m',r)
bench_twacePow = bench (twacePowDec :: t m' r -> t m r)

{-# INLINABLE bench_twaceCRT #-}
bench_twaceCRT :: forall t m m' r . (Tensor t, TElt t r, Fact m, _)
  => t m' r -> Bench '(t,m,m',r)
bench_twaceCRT = bench (fromJust' "TensorBenches.bench_twaceCRT" twaceCRT :: t m' r -> t m r)

{-# INLINABLE bench_embedPow #-}
bench_embedPow :: forall t m m' r . (Tensor t, TElt t r, Fact m', _)
  => t m r -> Bench '(t,m,m',r)
bench_embedPow = bench (embedPow :: t m r -> t m' r)

{-# INLINABLE bench_embedDec #-}
bench_embedDec :: forall t m m' r . (Tensor t, TElt t r, Fact m', _)
  => t m r -> Bench '(t,m,m',r)
bench_embedDec = bench (embedDec :: t m r -> t m' r)

{-# INLINABLE bench_embedCRT #-}
bench_embedCRT :: forall t m m' r . (Tensor t, TElt t r, Fact m', _)
  => t m r -> Bench '(t,m,m',r)
bench_embedCRT = bench (fromJust' "TensorBenches.bench_embedCRT" embedCRT :: t m r -> t m' r)
