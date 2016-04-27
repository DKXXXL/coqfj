module FJ.Syntax.Skelfj_syntax where

-- Haskell module generated by the BNF converter

import FJ.Syntax.Absfj_syntax
import FJ.Syntax.ErrM
type Result = Err String

failure :: Show a => a -> Result
failure x = Bad $ "Undefined case: " ++ show x

transId :: Id -> Result
transId x = case x of
  Id str  -> failure x


transProgram :: Program -> Result
transProgram x = case x of
  CProgram classdecls exp  -> failure x


transClassDecl :: ClassDecl -> Result
transClassDecl x = case x of
  CDecl id classname fielddecls constructor methoddecls  -> failure x


transFieldDecl :: FieldDecl -> Result
transFieldDecl x = case x of
  FDecl classname id  -> failure x


transConstructor :: Constructor -> Result
transConstructor x = case x of
  KDecl id fieldparams arguments assignments  -> failure x


transFieldParam :: FieldParam -> Result
transFieldParam x = case x of
  Field classname id  -> failure x


transFormalArg :: FormalArg -> Result
transFormalArg x = case x of
  FArg classname id  -> failure x


transArgument :: Argument -> Result
transArgument x = case x of
  Arg id  -> failure x


transAssignment :: Assignment -> Result
transAssignment x = case x of
  Assgnmt id1 id2  -> failure x


transMethodDecl :: MethodDecl -> Result
transMethodDecl x = case x of
  MDecl classname id formalargs exp  -> failure x


transExp :: Exp -> Result
transExp x = case x of
  ExpVar id  -> failure x
  ExpFieldAccess access id  -> failure x
  ExpMethodInvoc access id exps  -> failure x
  CastExp classname exp  -> failure x
  NewExp classname exps  -> failure x


transAccess :: Access -> Result
transAccess x = case x of
  ThisAccess  -> failure x
  ExpAccess exp  -> failure x


transClassName :: ClassName -> Result
transClassName x = case x of
  ClassObject  -> failure x
  ClassId id  -> failure x



