-- This Happy file was machine-generated by the BNF converter
{
{-# OPTIONS_GHC -fno-warn-incomplete-patterns -fno-warn-overlapping-patterns #-}
module FJ.Syntax.Parfj_syntax where
import FJ.Syntax.Absfj_syntax
import FJ.Syntax.Lexfj_syntax
import FJ.Syntax.ErrM

}

%name pProgram Program
%name pClassDecl ClassDecl
%name pFieldDecl FieldDecl
%name pConstructor Constructor
%name pFormalArg FormalArg
%name pArgument Argument
%name pAssignment Assignment
%name pMethodDecl MethodDecl
%name pExp Exp
%name pVar Var
%name pClassName ClassName
%name pListClassDecl ListClassDecl
%name pListFieldDecl ListFieldDecl
%name pListMethodDecl ListMethodDecl
%name pListFormalArg ListFormalArg
%name pListArgument ListArgument
%name pListAssignment ListAssignment
%name pListExp ListExp

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
 'return' { PT _ (TS _ 11) }
 'super' { PT _ (TS _ 12) }
 'this' { PT _ (TS _ 13) }
 '{' { PT _ (TS _ 14) }
 '}' { PT _ (TS _ 15) }

L_Id { PT _ (T_Id $$) }
L_err    { _ }


%%

Id    :: { Id} : L_Id { Id ($1)}

Program :: { Program }
Program : ListClassDecl Exp { CProgram (reverse $1) $2 } 


ClassDecl :: { ClassDecl }
ClassDecl : 'class' Id 'extends' ClassName '{' ListFieldDecl Constructor ListMethodDecl '}' { CDecl $2 $4 (reverse $6) $7 (reverse $8) } 


FieldDecl :: { FieldDecl }
FieldDecl : ClassName Id ';' { FDecl $1 $2 } 


Constructor :: { Constructor }
Constructor : Id '(' ListFormalArg ')' '{' 'super' '(' ListArgument ')' ';' ListAssignment '}' { KDecl $1 $3 $8 (reverse $11) } 


FormalArg :: { FormalArg }
FormalArg : ClassName Id { FArg $1 $2 } 


Argument :: { Argument }
Argument : Id { Arg $1 } 


Assignment :: { Assignment }
Assignment : 'this' '.' Id '=' Id ';' { Assgnmt $3 $5 } 


MethodDecl :: { MethodDecl }
MethodDecl : ClassName Id '(' ListFormalArg ')' '{' 'return' Exp ';' '}' { MDecl $1 $2 $4 $8 } 


Exp :: { Exp }
Exp : Var { ExpVar $1 } 
  | Exp '.' Id { ExpFieldAccess $1 $3 }
  | Exp '.' Id '(' ListExp ')' { ExpMethodInvoc $1 $3 $5 }
  | '(' ClassName ')' Exp { ExpCast $2 $4 }
  | 'new' Id '(' ListExp ')' { ExpNew $2 $4 }


Var :: { Var }
Var : 'this' { This } 
  | Id { VarId $1 }


ClassName :: { ClassName }
ClassName : 'Object' { ClassObject } 
  | Id { ClassId $1 }


ListClassDecl :: { [ClassDecl] }
ListClassDecl : {- empty -} { [] } 
  | ListClassDecl ClassDecl { flip (:) $1 $2 }


ListFieldDecl :: { [FieldDecl] }
ListFieldDecl : {- empty -} { [] } 
  | ListFieldDecl FieldDecl { flip (:) $1 $2 }


ListMethodDecl :: { [MethodDecl] }
ListMethodDecl : {- empty -} { [] } 
  | ListMethodDecl MethodDecl { flip (:) $1 $2 }


ListFormalArg :: { [FormalArg] }
ListFormalArg : {- empty -} { [] } 
  | FormalArg { (:[]) $1 }
  | FormalArg ',' ListFormalArg { (:) $1 $3 }


ListArgument :: { [Argument] }
ListArgument : {- empty -} { [] } 
  | Argument { (:[]) $1 }
  | Argument ',' ListArgument { (:) $1 $3 }


ListAssignment :: { [Assignment] }
ListAssignment : {- empty -} { [] } 
  | ListAssignment Assignment { flip (:) $1 $2 }


ListExp :: { [Exp] }
ListExp : {- empty -} { [] } 
  | Exp { (:[]) $1 }
  | Exp ',' ListExp { (:) $1 $3 }



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

