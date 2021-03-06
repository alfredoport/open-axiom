-- Copyright (c) 1991-2002, The Numerical Algorithms Group Ltd.
-- All rights reserved.
-- Copyright (C) 2007-2011, Gabriel Dos Reis.
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are
-- met:
--
--     - Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--
--     - Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in
--       the documentation and/or other materials provided with the
--       distribution.
--
--     - Neither the name of The Numerical Algorithms Group Ltd. nor the
--       names of its contributors may be used to endorse or promote products
--       derived from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
-- IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
-- PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
-- OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
-- PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
-- LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
-- NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


import vmlisp
namespace BOOT

$ruleSetsInitialized := false

--% Mode and Type Resolution Rule Data and Ruleset Creation

--% resolveTT Rules

-- These rules are applied only once at the outermost position of a term
-- some things can't be done by term rewriting conveniently (e.g. set
-- difference), so a form is created which is interpreted by
-- resolveTTRed later. The meanings of these forms are:
-- Incl(x,y): y if x is a member of y, failed otherwise
-- SetEqual(x,y): x if y is a permutation of x, failed otherwise
-- SetComp(x,y): x-y, if y is a subset of x, failed otherwise
-- SetInter(x,y): intersection of x and y, if nonempty, failed otherwise
-- SetDiff(x,y): x-y, if x and y have a nonempty intersection, failed ...

-- These first rules will be expanded for each of MP, DMP and NDMP

$mpolyTTRules == '( _
  ((Resolve (RN) (mpoly1 x t1)) . (mpoly1 x (Resolve (RN) t1))) _
  ((Resolve (UP x t1) (mpoly1 y t2)) . _
    (Resolve t1 (mpoly1 (Incl x y) t2))) _
  ((Resolve (mpoly1 x t1) (G t2)) . _
    (mpoly1 x (G (VarEqual t1 t2)))) _
  ((Resolve (VARIABLE x) (mpoly1 y t2)) . _
    (mpoly1 (Incl x y) t2)) _
  ((Resolve (mpoly1 x t1) (mpoly1 y t2)) . _
    (mpoly1 (SetEqual x y) (Resolve t1 t2))) _
  ((Resolve (mpoly1 x t1) (mpoly1 y t2)) . _
    (mpoly1 x (Resolve t1 (mpoly1 (SetComp y x) t2)))) _
  ((Resolve (mpoly1 x t1) (mpoly1 y t2)) . _
    (mpoly1 y (Resolve (mpoly1 (SetComp x y) t1) t2))) _
  ((Resolve (mpoly1 x t1) (mpoly1 y t2)) . _
    (mpoly1 (SetInter x y) (Resolve _
      (mpoly1 (SetDiff x y) t1) (mpoly1 (SetDiff y x) t2)))) _
  )

-- These are the general rules, excluding those above.

$generalTTRules == '( _
  ((Resolve (L (L t1)) (M t2)) . (M (Resolve t1 t2))) _
  ((Resolve (EQ t1) (B)) . (B)) _
  ((Resolve (SY) t1) . (Resolve (P (I)) t1)) _
  ((Resolve (M t1) (SM x t2)) . (M (Resolve t1 t2))) _
  ((Resolve (M t1) (RM x y t2)) . (M (Resolve t1 t2))) _
  ((Resolve (SM x t1) (RM y y t2)) . _
    (SM (VarEqual x y) (Resolve t1 t2))) _
  ((Resolve (V t1) (L t2)) . (V (Resolve t1 t2))) _
  ((Resolve (FF t1) (FR t2)) . (FR (Resolve t1 t2))) _
  ((Resolve (F) (RN)) . (F) ) _
 _
  ((Resolve (OV x) (OV y)) . (OV (SetUnion x y))) _
  ((Resolve (P t1) (UP y t2)) . (Resolve (P t1) t2)) _
 _
  ((Resolve (UP y t1) (G t2)) . (UP y (G (VarEqual t1 t2)))) _
  ((Resolve (P t1) (P t2)) . (P (Resolve t1 t2))) _
  ((Resolve (G t1) (G t2)) . (G (Resolve t1 t2))) _
  ((Resolve (G t1) (P t2)) . (P (G (VarEqual t1 t2)))) _
 _
  ((Resolve (AF t1) (EF t2)) . (EF (Resolve t1 t2))) _
  ((Resolve (AF t1) (LF t2)) . (LF (Resolve t1 t2))) _
  ((Resolve (AF t1) (FE t2)) . (FE (Resolve t1 t2))) _
  ((Resolve (EF t1) (LF t2)) . (LF (Resolve t1 t2))) _
  ((Resolve (EF t1) (FE t2)) . (FE (Resolve t1 t2))) _
  ((Resolve (LF t1) (FE t2)) . (FE (Resolve t1 t2))) _
 _
  ((Resolve (RN) (P t1)) . (P (Resolve (RN) t1))) _
  ((Resolve (RN) (UP x t1)) . (UP x (Resolve (RN) t1))) _
  ((Resolve (RN) (UPS x t1)) . (UPS x (Resolve (RN) t1))) _
  ((Resolve (RN) (CFPS x t1)) . (CFPS x (Resolve (RN) t1))) _
 _
  ((Resolve (RR) (EF t1)) . (EF (Resolve (RR) t1))) _
  ((Resolve (P t1) (AF t2)) . (AF (Resolve t1 t2 ))) _
  ((Resolve (P t1) (EF t2)) . (EF (Resolve t1 t2 ))) _
  ((Resolve (P t1) (LF t2)) . (LF (Resolve t1 t2 ))) _
 _
  ((Resolve (MP x t1) (DMP y t2)) . _
    (MP (SetEqual x y) (Resolve t1 t2))) _
  ((Resolve (MP x t1) (DMP y t2)) . _
    (MP x (Resolve t1 (DMP (SetComp y x) t2)))) _
  ((Resolve (MP x t1) (DMP y t2)) . _
    (MP y (Resolve (MP (SetComp x y) t1) t2))) _
  ((Resolve (MP x t1) (DMP y t2)) . _
    (MP (SetInter x y) (Resolve _
      (MP (SetDiff x y) t1) (DMP (SetDiff y x) t2)))) _
 _
  ((Resolve (MP x t1) (NDMP y t2)) . _
    (MP (SetEqual x y) (Resolve t1 t2))) _
  ((Resolve (MP x t1) (NDMP y t2)) . _
    (MP x (Resolve t1 (NDMP (SetComp y x) t2)))) _
  ((Resolve (MP x t1) (NDMP y t2)) . _
    (MP y (Resolve (MP (SetComp x y) t1) t2))) _
  ((Resolve (MP x t1) (NDMP y t2)) . _
    (MP (SetInter x y) (Resolve _
      (MP (SetDiff x y) t1) (NDMP (SetDiff y x) t2)))) _
 _
  ((Resolve (DMP x t1) (NDMP y t2)) . _
    (DMP (SetEqual x y) (Resolve t1 t2))) _
  ((Resolve (DMP x t1) (NDMP y t2)) . _
    (DMP x (Resolve t1 (NDMP (SetComp y x) t2)))) _
  ((Resolve (DMP x t1) (NDMP y t2)) . _
    (DMP y (Resolve (DMP (SetComp x y) t1) t2))) _
  ((Resolve (DMP x t1) (NDMP y t2)) . _
    (DMP (SetInter x y) (Resolve _
      (DMP (SetDiff x y) t1) (NDMP (SetDiff y x) t2)))) _
  )

-- The following creates the ruleset

createResolveTTRules() ==
  -- expand multivariate polynomial rules
  mps := '(MP DMP NDMP)
  mpRules := "append"/[substitute(mp,'mpoly1,$mpolyTTRules) for mp in mps]
  $Res := ['(t1 t2 x y),
    :applySubst(pairList($abList,$nameList),append($generalTTRules,mpRules))]
  true

--% resolveTM Rules

-- Same rules as for resolveTT, with two exceptions:
-- Diff(x,y): removes y from x, if possible, failed otherwise
-- SetIncl(x,y): y if x is a subset of y, failed otherwise

-- These first rules will be expanded for each of MP, DMP and NDMP

$mpolyTMRules == '( _
  ((Resolve (mpoly1 x t1) (P t2)) . (Resolve t1 (P t2))) _
  ((Resolve (mpoly1 (x) t1) (UP x t2)) . (UP x (Resolve t1 t2))) _
  ((Resolve (mpoly1 x t1) (UP y t2)) . _
    (UP y (Resolve (mpoly1 (Diff x y) t1) t2))) _
  ((Resolve (UP x t1) (mpoly1 y t2)) . _
    (Resolve t1 (mpoly1 (Incl x y) t2))) _
  ((Resolve (VARIABLE x) (mpoly1 y t2)) . _
    (mpoly1 (Incl x y) (Resolve (I) t2))) _
  ((Resolve (mpoly1 x t1) (mpoly2 y t2)) . _
    (Resolve t1 (mpoly2 (SetIncl x y) t2))) _
  ((Resolve (mpoly1 x t1) (mpoly2 y t2)) . _
    (mpoly2 y (Resolve (mpoly1 (SetComp x y) t1) t2))) _
  ((Resolve (mpoly1 x t1) (mpoly2 y t2)) . _
    (Resolve (mpoly1 (SetDiff x y) t1) (mpoly2 y t2))) _
 )

-- These are the general rules, excluding those above.

$generalTMRules == '( _
  ((Resolve (VARIABLE x) (P t1)) . (P (Resolve (I) t1))) _
  ((Resolve (VARIABLE x) (UP y t1)) . _
    (UP (VarEqual x y) (Resolve (I) t1))) _
  ((Resolve (VARIABLE x) (UPS y t1)) . _
    (UPS (VarEqual x y) (Resolve (I) t1))) _
  ((Resolve (VARIABLE x) (CFPS y t1)) . _
    (CFPS (VarEqual x y) (Resolve (RN) t1))) _
  ((Resolve (VARIABLE x) (ELFPS y t1)) . _
    (ELFPS (VarEqual x y) (Resolve (RN) t1))) _
  ((Resolve (VARIABLE x) (EF t1)) . (EF t1)) _
  ((Resolve (L (L (SY))) (M _*_*)) . (M (P (I)))) _
  ((Resolve (L (L (SY))) (SM x _*_*)) . (SM x (P (I)))) _
  ((Resolve (L (L t1)) (M t2)) . (M (Resolve t1 t2))) _
  ((Resolve (L (L t1)) (SM x t2)) . (SM x (Resolve t1 t2))) _
  ((Resolve (L (L t1)) (RM x y t2)) . (RM x y (Resolve t1 t2))) _
  ((Resolve (SY) t1) . (Resolve (P (I)) t1)) _
  ((Resolve (VARIABLE x) t1) . (Resolve (P (I)) t1)) _
  ((Resolve (SM x t1) (M t2)) . (M (Resolve t1 t2))) _
  ((Resolve (RM x y t1) (M t2)) . (M (Resolve t1 t2))) _
 _
  ((Resolve (M t1) (L _*_*)) . (L (L t1))) _
  ((Resolve (SM x t1) (L _*_*)) . (L (L t1))) _
  ((Resolve (RM x y t1) (L _*_*)) . (L (L t1))) _
  ((Resolve (M t1) (L t2)) . (L (Resolve (L t1) t2))) _
  ((Resolve (SM x t1) (L t2)) . (L (Resolve (L t1) t2))) _
  ((Resolve (RM x y t1) (L t2)) . (L (Resolve (L t1) t2))) _
 _
  ((Resolve (M t1) (V _*_*)) . (V (V t1))) _
  ((Resolve (SM x t1) (V _*_*)) . (V (V t1))) _
  ((Resolve (RM x y t1) (V _*_*)) . (V (V t1))) _
  ((Resolve (M t1) (V t2)) . (V (Resolve (V t1) t2))) _
  ((Resolve (SM x t1) (V t2)) . (V (Resolve (V t1) t2))) _
  ((Resolve (RM x y t1) (V t2)) . (V (Resolve (V t1) t2))) _
 _
  ((Resolve (L t1) (V t2)) . (V (Resolve t1 t2))) _
  ((Resolve (V t1) (L t2)) . (L (Resolve t1 t2))) _
  ((Resolve (FF t1) (FR t2)) . (FR (Resolve t1 t2))) _
  ((Resolve (UP x t1) (P t2)) . (Resolve t1 (P t2))) _
 )

-- Private abbreviation table for resolve rules
$resolveAbbreviations == '( _
    (P .  Polynomial) _
    (G .  Gaussian) _
    (L .  List) _
    (M .  Matrix) _
    (EQ . Equation) _
    (B .  Boolean) _
    (SY . Symbol) _
    (I .  Integer) _
    (SM . SquareMatrix) _
    (RM . RectangularMatrix) _
    (V .  Vector) _
    (FF . FactoredForm) _
    (FR . FactoredRing) _
    (RN . RationalNumber) _
    (F .  Float) _
    (OV . OrderedVariableList) _
    (UP . UnivariatePoly) _
    (DMP . DistributedMultivariatePolynomial) _
    (MP . MultivariatePolynomial) _
    (HDMP . HomogeneousDistributedMultivariatePolynomial) _
    (QF . QuotientField) _
    (RF . RationalFunction) _
    (RE . RadicalExtension) _
    (RR . RationalRadicals) _
    (UPS . UnivariatePowerSeries) _
    (CFPS . ContinuedFractionPowerSeries) _
    (ELFPS . EllipticFunctionPowerSeries) _
    (EF . ElementaryFunction) _
    (VARIABLE . Variable) _
 )

$newResolveAbbreviations == '( _
    (P .  Polynomial) _
    (G .  Complex) _
    (L .  List) _
    (M .  Matrix) _
    (EQ . Equation) _
    (B .  Boolean) _
    (SY . Symbol) _
    (I .  Integer) _
    (SM . SquareMatrix) _
    (RM . RectangularMatrix) _
    (V .  Vector) _
    (FF . Factored) _
    (FR . Factored) _
    (F .  Float) _
    (OV . OrderedVariableList) _
    (UP . UnivariatePolynomial) _
    (DMP . DistributedMultivariatePolynomial) _
    (MP . MultivariatePolynomial) _
    (HDMP . HomogeneousDistributedMultivariatePolynomial) _
    (QF . Fraction) _
    (UPS . UnivariatePowerSeries) _
    (VARIABLE . Variable) _
 )

-- The following creates the ruleset

createResolveTMRules() ==
  -- expand multivariate polynomial rules
  mps := '(MP DMP NDMP)
  mpRules0 := "append"/[substitute(mp,'mpoly1,$mpolyTMRules) for mp in mps]
  mpRules := "append"/[substitute(mp,'mpoly2,mpRules0) for mp in mps]
  $ResMode := ['(t1 t2 x y),
    :applySubst(pairList($abList,$nameList),append(mpRules,$generalTMRules))]
  true

createTypeEquivRules() ==
  -- used by eqType, for example
  $TypeEQ := ['(t1), :applySubst(pairList($abList,$nameList),'(
    ((QF (P t1)) . (RF t1))
      ((QF (I)) . (RN))
        ((RE (RN)) . (RR)) ))]
  $TypeEqui := [first $TypeEQ, :[[b,:a] for [a,:b] in rest $TypeEQ]]
  true

initializeRuleSets() ==
  $abList: local :=
    ASSOCLEFT $newResolveAbbreviations
  $nameList: local :=
    ASSOCRIGHT $newResolveAbbreviations
  createResolveTTRules()
  createResolveTMRules()
  createTypeEquivRules()
  $ruleSetsInitialized := true
  true
