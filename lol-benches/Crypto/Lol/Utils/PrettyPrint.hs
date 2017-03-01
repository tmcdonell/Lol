{-|
Module      : Crypto.Lol.Utils.PrettyPrint
Description : Pretty-printing for benchmark results.
Copyright   : (c) Eric Crockett, 2011-2017
                  Chris Peikert, 2011-2017
License     : GPL-2
Maintainer  : ecrockett0@email.com
Stability   : experimental
Portability : POSIX

Pretty-printing for benchmark results.
-}

{-# LANGUAGE BangPatterns    #-}
{-# LANGUAGE RecordWildCards #-}

module Crypto.Lol.Utils.PrettyPrint
(getTableName
,getBenchParams
,getBenchLvl
,getBenchFunc
,getReports
,getRuntime
,col
,testName
,OptsInternal(..)
,Verb(..)) where

import Control.Monad (foldM, when)
import Control.Monad.IO.Class (MonadIO, liftIO)

import Criterion.Internal (runAndAnalyseOne)
import Criterion.Main.Options (defaultConfig)
import Criterion.Measurement (secs)
import Criterion.Monad (Criterion, withConfig)
import Criterion.Types

import Data.List.Split
import qualified Data.Map as Map
import Data.Maybe

import Statistics.Resampling.Bootstrap (Estimate(..))

-- | Verbosity of benchmark output.
data Verb = Progress  -- ^ prints a '.' when each benchmark completes
          | Abridged  -- ^ prints a one-line summary for each benchmark
          | Full      -- ^ prints full criterion output for each benchmark
          deriving (Eq)

-- | Options for printing benchmark summary
data OptsInternal = OptsInternal
  {verb          :: Verb,     -- ^ Verbosity
   levels        :: [String], -- ^ Which levels of Lol to benchmark
   benches       :: [String], -- ^ Which operations to benchmark
   params        :: [String], -- ^ Which parameters to benchmark
   redThreshold  :: Double,   -- ^ How many times larger a benchmark
                              --   must be (compared to the minimum
                              --   benchmark for that parameter,
                              --   across all levels), to be printed in red
   colWidth      :: Int,      -- ^ Character width of data columns
   testNameWidth :: Int}      -- ^ Character width of row labels

col, testName :: OptsInternal -> String
testName OptsInternal{..} = "%-" ++ show testNameWidth ++ "s "
col OptsInternal{..} = "%-" ++ show colWidth ++ "s "

parseBenchName :: String -> [String]
parseBenchName = wordsBy (=='/')

getTableName :: String -> String
getTableName   = (!! 0) . parseBenchName

getBenchParams :: String -> String
getBenchParams = (!! 1) . parseBenchName

getBenchLvl :: String -> String
getBenchLvl    = (!! 2) . parseBenchName

getBenchFunc :: String -> String
getBenchFunc   = (!! 3) . parseBenchName

getReports :: OptsInternal -> Benchmark -> IO [Report]
getReports o = withConfig (config o) . runAndAnalyse o

config :: OptsInternal -> Config
config OptsInternal{..} = defaultConfig {verbosity = if verb == Full then Normal else Quiet}

-- | Run, and analyse, one or more benchmarks.
-- From Criterion.Internal
runAndAnalyse :: OptsInternal -> Benchmark -> Criterion [Report]
runAndAnalyse o@OptsInternal{..} bs = for o bs $ \idx desc bm -> do
  when (verb == Abridged || verb == Full) $ liftIO $ putStr $ "benchmark " ++ desc
  when (verb == Full) $ liftIO $ putStrLn ""
  (Analysed rpt) <- runAndAnalyseOne idx desc bm
  when (verb == Progress) $ liftIO $ putStr "."
  when (verb == Abridged) $ liftIO $ putStrLn $ "..." ++ secs (getRuntime rpt)
  return rpt

getRuntime :: Report -> Double
getRuntime Report{..} =
  let SampleAnalysis{..} = reportAnalysis
      (builtin, _) = splitAt 1 anRegress
      mests = map (\Regression{..} -> Map.lookup "iters" regCoeffs) builtin
      [Estimate{..}] = catMaybes mests
  in estPoint

-- | Iterate over benchmarks.
-- From Criterion.Internal
for :: MonadIO m => OptsInternal -> Benchmark -> (Int -> String -> Benchmarkable -> m a) -> m [a]
for OptsInternal{..} bs0 handle = snd <$> go (0::Int, []) ("", bs0)
  where
    select name =
      let param = getBenchParams name
          lvl   = getBenchLvl    name
          func  = getBenchFunc   name
      in (lvl `elem` levels) && (func `elem` benches) && (param `elem` params)
    go (!idx, drs) (pfx, Benchmark desc b)
      | select desc' = do
          x <- handle idx desc' b;
          return (idx + 1, x:drs)
      | otherwise = do
          liftIO $ putStrLn desc'
          return (idx, drs)
      where desc' = addPrefix pfx desc
    go (!idx,drs) (pfx, BenchGroup desc bs) =
      foldM go (idx,drs) [(addPrefix pfx desc, b) | b <- bs]
