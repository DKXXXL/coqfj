-- This Happy file was machine-generated by the BNF converter
{
{-# OPTIONS_GHC -fno-warn-incomplete-patterns -fno-warn-overlapping-patterns #-}
module FFJ.Syntax.Parffj_syntax where
import FFJ.Syntax.Absffj_syntax
import FFJ.Syntax.Lexffj_syntax
import FFJ.Syntax.ErrM

}

%name pCDList CDList
%name pCDef CDef
%name pCD CD
%name pCR CR
%name pFD FD
%name pKD KD
%name pKR KR
%name pField Field
%name pFormalArg FormalArg
%name pArg Arg
%name pAssignment Assignment
%name pMD MD
%name pMR MR
%name pType Type
%name pTerm Term
%name pExp Exp
%name pListCDef ListCDef
%name pListFD ListFD
%name pListMD ListMD
%name pListMR ListMR
%name pListField ListField
%name pListFormalArg ListFormalArg
%name pListArg ListArg
%name pListAssignment ListAssignment
%name pListTerm ListTerm

-- no lexer declaration
%monad { Err } { thenM } { returnM }
%tokentype { Token }

%token 
 '(' { PT _ (TS _ 1) }
 ')' { PT _ (TS _ 2) }
 ',' { PT _ (TS _ 3) }
 '.' { PT _ (TS _ 4) }
 ';' { PT _ (TS _ 5) }
 '=' { PT _ (TS _ 6) }
 'Object' { PT _ (TS _ 7) }
 'class' { PT _ (TS _ 8) }
 'extends' { PT _ (TS _ 9) }
 'new' { PT _ (TS _ 10) }
 'original' { PT _ (TS _ 11) }
 'refines' { PT _ (TS _ 12) }
 'return' { PT _ (TS _ 13) }
 'super' { PT _ (TS _ 14) }
 'this' { PT _ (TS _ 15) }
 '{' { PT _ (TS _ 16) }
 '}' { PT _ (TS _ 17) }

L_Id { PT _ (T_Id $$) }
L_err    { _ }


%%

Id    :: { Id} : L_Id { Id ($1)}

CDList :: { CDList }
CDList : ListCDef Exp { CDList (reverse $1) $2 } 


CDef :: { CDef }
CDef : CD { CDDecl $1 } 
  | CR { CDRef $1 }


CD :: { CD }
CD : 'class' Id 'extends' Type '{' ListFD KD ListMD '}' { CDecl $2 $4 (reverse $6) $7 (reverse $8) } 


CR :: { CR }
CR : 'refines' 'class' Id '{' ListFD KR ListMD ListMR '}' { CRef $3 (reverse $5) $6 (reverse $7) (reverse $8) } 


FD :: { FD }
FD : Type Id ';' { FDecl $1 $2 } 


KD :: { KD }
KD : Id '(' ListField ')' '{' 'super' '(' ListArg ')' ';' ListAssignment '}' { KDecl $1 $3 $8 (reverse $11) } 


KR :: { KR }
KR : 'refines' Id '(' ListField ')' '{' 'original' '(' ListArg ')' ';' ListAssignment '}' { KRef $2 $4 $9 (reverse $12) } 


Field :: { Field }
Field : Type Id { Field $1 $2 } 


FormalArg :: { FormalArg }
FormalArg : Type Id { FormalArg $1 $2 } 


Arg :: { Arg }
Arg : Id { Arg $1 } 


Assignment :: { Assignment }
Assignment : 'this' '.' Id '=' Id ';' { Assignment $3 $5 } 


MD :: { MD }
MD : Type Id '(' ListFormalArg ')' '{' 'return' Term ';' '}' { MethodDecl $1 $2 $4 $8 } 


MR :: { MR }
MR : 'refines' Id Id '(' ListFormalArg ')' '{' 'return' Term ';' '}' { MethodRef $2 $3 $5 $9 } 


Type :: { Type }
Type : 'Object' { TypeObject } 
  | Id { TypeId $1 }


Term :: { Term }
Term : Id { TermVar $1 } 
  | Term '.' Id { TermFieldAccess $1 $3 }
  | Term '.' Id '(' ListTerm ')' { TermMethodInvoc $1 $3 $5 }
  | Exp { TermExp $1 }


Exp :: { Exp }
Exp : '(' Type ')' Term { CastExp $2 $4 } 
  | 'new' Id '(' ListTerm ')' { NewExp $2 $4 }


ListCDef :: { [CDef] }
ListCDef : {- empty -} { [] } 
  | ListCDef CDef { flip (:) $1 $2 }


ListFD :: { [FD] }
ListFD : {- empty -} { [] } 
  | ListFD FD { flip (:) $1 $2 }


ListMD :: { [MD] }
ListMD : {- empty -} { [] } 
  | ListMD MD { flip (:) $1 $2 }


ListMR :: { [MR] }
ListMR : {- empty -} { [] } 
  | ListMR MR { flip (:) $1 $2 }


ListField :: { [Field] }
ListField : {- empty -} { [] } 
  | Field { (:[]) $1 }
  | Field ',' ListField { (:) $1 $3 }


ListFormalArg :: { [FormalArg] }
ListFormalArg : {- empty -} { [] } 
  | FormalArg { (:[]) $1 }
  | FormalArg ',' ListFormalArg { (:) $1 $3 }


ListArg :: { [Arg] }
ListArg : {- empty -} { [] } 
  | Arg { (:[]) $1 }
  | Arg ',' ListArg { (:) $1 $3 }


ListAssignment :: { [Assignment] }
ListAssignment : {- empty -} { [] } 
  | ListAssignment Assignment { flip (:) $1 $2 }


ListTerm :: { [Term] }
ListTerm : {- empty -} { [] } 
  | Term { (:[]) $1 }
  | Term ',' ListTerm { (:) $1 $3 }



{

returnM :: a -> Err a
returnM = return

thenM :: Err a -> (a -> Err b) -> Err b
thenM = (>>=)

happyError :: [Token] -> Err a
happyError ts =
  Bad $ "syntax error at " ++ tokenPos ts ++ 
  case ts of
    [] -> []
    [Err _] -> " due to lexer error"
    _ -> " before " ++ unwords (map (id . prToken) (take 4 ts))

myLexer = tokens
}

