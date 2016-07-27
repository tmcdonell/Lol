{-# LANGUAGE DataKinds            #-}
{-# LANGUAGE FlexibleContexts     #-}
{-# LANGUAGE NoImplicitPrelude    #-}
{-# LANGUAGE ScopedTypeVariables  #-}
{-# LANGUAGE TypeFamilies         #-}
{-# LANGUAGE TypeOperators        #-}
{-# LANGUAGE UndecidableInstances #-}

{-# OPTIONS_GHC -fno-warn-missing-signatures #-}

module SimpleTensorBenches (simpleTensorBenches1, simpleTensorBenches2) where

import Control.Applicative
import Control.Monad.Random

import Crypto.Lol.Prelude
import Crypto.Lol.Cyclotomic.Tensor
import Crypto.Lol.Types
import Crypto.Random.DRBG

import BenchConfig
import Criterion

{-# INLINE simpleTensorBenches1 #-}
simpleTensorBenches1 (Proxy :: Proxy '(t,m,r)) = do
  x1 :: t m (r, r) <- getRandom
  x2 :: t m r <- getRandom
  x3 :: t m r <- getRandom
  gen <- newGenIO
  return $ bgroup "STensor" [
    bench "unzipPow"    $ nf unzipT x1,
    bench "unzipDec"    $ nf unzipT x1,
    bench "unzipCRT"    $ nf unzipT x1,
    bench "zipWith (*)" $ nf (zipWithT (*) x2) x3,
    bench "crt"         $ nf (fromJust' "SimpleTensorBenches.crt" crt) x2,
    bench "crtInv"      $ nf (fromJust' "SimpleTensorBenches.crtInv" crtInv) x2,
    bench "l"           $ nf l x2,
    bench "lInv"        $ nf lInv x2,
    bench "*g Pow"      $ nf mulGPow x2,
    bench "*g CRT"      $ nf (fromJust' "SimpleTensorBenches.gcrt" mulGCRT) x2,
    bench "lift"        $ nf (fmapT lift) x2,
    bench "error"       $ nf (evalRand (fmapT (roundMult one) <$>
                           (tGaussianDec (0.1 :: Double) :: Rand (CryptoRand Gen) (t m Double))) :: CryptoRand Gen -> t m Int64) gen
    ]
{-# INLINE simpleTensorBenches2 #-}
simpleTensorBenches2 (Proxy :: Proxy '(t,m',m,r)) = do
  x2 :: t m r <- getRandom
  x4 :: t m' r <- getRandom
  return $ bgroup "STensor" [
    bench "twacePow" $ nf (twacePowDec :: t m r -> t m' r) x2,
    bench "twaceCRT" $ nf (fromJust' "SimpleTensorBenches.twaceCRT" twaceCRT :: t m r -> t m' r) x2,
    bench "embedPow" $ nf (embedPow :: t m' r -> t m r) x4,
    bench "embedDec" $ nf (embedDec :: t m' r -> t m r) x4
    ]