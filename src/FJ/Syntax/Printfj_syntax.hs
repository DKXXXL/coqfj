{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
module FJ.Syntax.Printfj_syntax where

-- pretty-printer generated by the BNF converter

import FJ.Syntax.Absfj_syntax
import Data.Char


-- the top-level printing method
printTree :: Print a => a -> String
printTree = render . prt 0

type Doc = [ShowS] -> [ShowS]

doc :: ShowS -> Doc
doc = (:)

render :: Doc -> String
render d = rend 0 (map ($ "") $ d []) "" where
  rend i ss = case ss of
    "["      :ts -> showChar '[' . rend i ts
    "("      :ts -> showChar '(' . rend i ts
    "{"      :ts -> showChar '{' . new (i+1) . rend (i+1) ts
    "}" : ";":ts -> new (i-1) . space "}" . showChar ';' . new (i-1) . rend (i-1) ts
    "}"      :ts -> new (i-1) . showChar '}' . new (i-1) . rend (i-1) ts
    ";"      :ts -> showChar ';' . new i . rend i ts
    t  : "," :ts -> showString t . space "," . rend i ts
    t  : ")" :ts -> showString t . showChar ')' . rend i ts
    t  : "]" :ts -> showString t . showChar ']' . rend i ts
    t        :ts -> space t . rend i ts
    _            -> id
  new i   = showChar '\n' . replicateS (2*i) (showChar ' ') . dropWhile isSpace
  space t = showString t . (\s -> if null s then "" else (' ':s))

parenth :: Doc -> Doc
parenth ss = doc (showChar '(') . ss . doc (showChar ')')

concatS :: [ShowS] -> ShowS
concatS = foldr (.) id

concatD :: [Doc] -> Doc
concatD = foldr (.) id

replicateS :: Int -> ShowS -> ShowS
replicateS n f = concatS (replicate n f)

-- the printer class does the job
class Print a where
  prt :: Int -> a -> Doc
  prtList :: [a] -> Doc
  prtList = concatD . map (prt 0)

instance Print a => Print [a] where
  prt _ = prtList

instance Print Char where
  prt _ s = doc (showChar '\'' . mkEsc '\'' s . showChar '\'')
  prtList s = doc (showChar '"' . concatS (map (mkEsc '"') s) . showChar '"')

mkEsc :: Char -> Char -> ShowS
mkEsc q s = case s of
  _ | s == q -> showChar '\\' . showChar s
  '\\'-> showString "\\\\"
  '\n' -> showString "\\n"
  '\t' -> showString "\\t"
  _ -> showChar s

prPrec :: Int -> Int -> Doc -> Doc
prPrec i j = if j<i then parenth else id


instance Print Integer where
  prt _ x = doc (shows x)


instance Print Double where
  prt _ x = doc (shows x)



instance Print Id where
  prt _ (Id i) = doc (showString ( i))



instance Print Program where
  prt i e = case e of
   CProgram classdecls exp -> prPrec i 0 (concatD [prt 0 classdecls , prt 0 exp])


instance Print ClassDecl where
  prt i e = case e of
   CDecl id classname fielddecls constructor methoddecls -> prPrec i 0 (concatD [doc (showString "class") , prt 0 id , doc (showString "extends") , prt 0 classname , doc (showString "{") , prt 0 fielddecls , prt 0 constructor , prt 0 methoddecls , doc (showString "}")])

  prtList es = case es of
   [] -> (concatD [])
   x:xs -> (concatD [prt 0 x , prt 0 xs])

instance Print FieldDecl where
  prt i e = case e of
   FDecl classname id -> prPrec i 0 (concatD [prt 0 classname , prt 0 id , doc (showString ";")])

  prtList es = case es of
   [] -> (concatD [])
   x:xs -> (concatD [prt 0 x , prt 0 xs])

instance Print Constructor where
  prt i e = case e of
   KDecl id fieldparams arguments assignments -> prPrec i 0 (concatD [prt 0 id , doc (showString "(") , prt 0 fieldparams , doc (showString ")") , doc (showString "{") , doc (showString "super") , doc (showString "(") , prt 0 arguments , doc (showString ")") , doc (showString ";") , prt 0 assignments , doc (showString "}")])


instance Print FieldParam where
  prt i e = case e of
   Field classname id -> prPrec i 0 (concatD [prt 0 classname , prt 0 id])

  prtList es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ",") , prt 0 xs])

instance Print FormalArg where
  prt i e = case e of
   FArg classname id -> prPrec i 0 (concatD [prt 0 classname , prt 0 id])

  prtList es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ",") , prt 0 xs])

instance Print Argument where
  prt i e = case e of
   Arg id -> prPrec i 0 (concatD [prt 0 id])

  prtList es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ",") , prt 0 xs])

instance Print Assignment where
  prt i e = case e of
   Assgnmt id0 id -> prPrec i 0 (concatD [doc (showString "this") , doc (showString ".") , prt 0 id0 , doc (showString "=") , prt 0 id , doc (showString ";")])

  prtList es = case es of
   [] -> (concatD [])
   x:xs -> (concatD [prt 0 x , prt 0 xs])

instance Print MethodDecl where
  prt i e = case e of
   MDecl classname id formalargs exp -> prPrec i 0 (concatD [prt 0 classname , prt 0 id , doc (showString "(") , prt 0 formalargs , doc (showString ")") , doc (showString "{") , doc (showString "return") , prt 0 exp , doc (showString ";") , doc (showString "}")])

  prtList es = case es of
   [] -> (concatD [])
   x:xs -> (concatD [prt 0 x , prt 0 xs])

instance Print Exp where
  prt i e = case e of
   ExpVar id -> prPrec i 0 (concatD [prt 0 id])
   ExpFieldAccess access id -> prPrec i 0 (concatD [prt 0 access , doc (showString ".") , prt 0 id])
   ExpMethodInvoc access id exps -> prPrec i 0 (concatD [prt 0 access , doc (showString ".") , prt 0 id , doc (showString "(") , prt 0 exps , doc (showString ")")])
   CastExp classname exp -> prPrec i 0 (concatD [doc (showString "(") , prt 0 classname , doc (showString ")") , prt 0 exp])
   NewExp classname exps -> prPrec i 0 (concatD [doc (showString "new") , prt 0 classname , doc (showString "(") , prt 0 exps , doc (showString ")")])

  prtList es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ",") , prt 0 xs])

instance Print Access where
  prt i e = case e of
   ThisAccess  -> prPrec i 0 (concatD [doc (showString "this")])
   ExpAccess exp -> prPrec i 0 (concatD [prt 0 exp])


instance Print ClassName where
  prt i e = case e of
   ClassObject  -> prPrec i 0 (concatD [doc (showString "Object")])
   ClassId id -> prPrec i 0 (concatD [prt 0 id])



