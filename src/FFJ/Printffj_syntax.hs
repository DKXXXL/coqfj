{-# OPTIONS -fno-warn-incomplete-patterns #-}
module FFJ.Printffj_syntax where

-- pretty-printer generated by the BNF converter

import FFJ.Absffj_syntax
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



instance Print CDList where
  prt i e = case e of
   CDList cdefs exp -> prPrec i 0 (concatD [prt 0 cdefs , prt 0 exp])


instance Print CDef where
  prt i e = case e of
   CDDecl cd -> prPrec i 0 (concatD [prt 0 cd])
   CDRef cr -> prPrec i 0 (concatD [prt 0 cr])

  prtList es = case es of
   [] -> (concatD [])
   x:xs -> (concatD [prt 0 x , prt 0 xs])

instance Print CD where
  prt i e = case e of
   CDecl id type' fds kd mds -> prPrec i 0 (concatD [doc (showString "class") , prt 0 id , doc (showString "extends") , prt 0 type' , doc (showString "{") , prt 0 fds , prt 0 kd , prt 0 mds , doc (showString "}")])


instance Print CR where
  prt i e = case e of
   CRef id fds kr mds mrs -> prPrec i 0 (concatD [doc (showString "refines") , doc (showString "class") , prt 0 id , doc (showString "{") , prt 0 fds , prt 0 kr , prt 0 mds , prt 0 mrs , doc (showString "}")])


instance Print FD where
  prt i e = case e of
   FDecl type' id -> prPrec i 0 (concatD [prt 0 type' , prt 0 id , doc (showString ";")])

  prtList es = case es of
   [] -> (concatD [])
   x:xs -> (concatD [prt 0 x , prt 0 xs])

instance Print KD where
  prt i e = case e of
   KDecl id fields args assignments -> prPrec i 0 (concatD [prt 0 id , doc (showString "(") , prt 0 fields , doc (showString ")") , doc (showString "{") , doc (showString "super") , doc (showString "(") , prt 0 args , doc (showString ")") , doc (showString ";") , prt 0 assignments , doc (showString "}")])


instance Print KR where
  prt i e = case e of
   KRef id fields args assignments -> prPrec i 0 (concatD [doc (showString "refines") , prt 0 id , doc (showString "(") , prt 0 fields , doc (showString ")") , doc (showString "{") , doc (showString "original") , doc (showString "(") , prt 0 args , doc (showString ")") , doc (showString ";") , prt 0 assignments , doc (showString "}")])


instance Print Field where
  prt i e = case e of
   Field type' id -> prPrec i 0 (concatD [prt 0 type' , prt 0 id])

  prtList es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ",") , prt 0 xs])

instance Print FormalArg where
  prt i e = case e of
   FormalArg type' id -> prPrec i 0 (concatD [prt 0 type' , prt 0 id])

  prtList es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ",") , prt 0 xs])

instance Print Arg where
  prt i e = case e of
   Arg id -> prPrec i 0 (concatD [prt 0 id])

  prtList es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ",") , prt 0 xs])

instance Print Assignment where
  prt i e = case e of
   Assignment id0 id -> prPrec i 0 (concatD [doc (showString "this") , doc (showString ".") , prt 0 id0 , doc (showString "=") , prt 0 id , doc (showString ";")])

  prtList es = case es of
   [] -> (concatD [])
   x:xs -> (concatD [prt 0 x , prt 0 xs])

instance Print MD where
  prt i e = case e of
   MethodDecl type' id formalargs term -> prPrec i 0 (concatD [prt 0 type' , prt 0 id , doc (showString "(") , prt 0 formalargs , doc (showString ")") , doc (showString "{") , doc (showString "return") , prt 0 term , doc (showString ";") , doc (showString "}")])

  prtList es = case es of
   [] -> (concatD [])
   x:xs -> (concatD [prt 0 x , prt 0 xs])

instance Print MR where
  prt i e = case e of
   MethodRef id0 id formalargs term -> prPrec i 0 (concatD [doc (showString "refines") , prt 0 id0 , prt 0 id , doc (showString "(") , prt 0 formalargs , doc (showString ")") , doc (showString "{") , doc (showString "return") , prt 0 term , doc (showString ";") , doc (showString "}")])

  prtList es = case es of
   [] -> (concatD [])
   x:xs -> (concatD [prt 0 x , prt 0 xs])

instance Print Type where
  prt i e = case e of
   TypeObject  -> prPrec i 0 (concatD [doc (showString "Object")])
   TypeId id -> prPrec i 0 (concatD [prt 0 id])


instance Print Term where
  prt i e = case e of
   TermVar id -> prPrec i 0 (concatD [prt 0 id])
   TermFieldAccess term id -> prPrec i 0 (concatD [prt 0 term , doc (showString ".") , prt 0 id])
   TermMethodInvoc term id terms -> prPrec i 0 (concatD [prt 0 term , doc (showString ".") , prt 0 id , doc (showString "(") , prt 0 terms , doc (showString ")")])
   TermExp exp -> prPrec i 0 (concatD [prt 0 exp])

  prtList es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ",") , prt 0 xs])

instance Print Exp where
  prt i e = case e of
   CastExp id term -> prPrec i 0 (concatD [doc (showString "(") , prt 0 id , doc (showString ")") , prt 0 term])
   NewExp id terms -> prPrec i 0 (concatD [doc (showString "new") , prt 0 id , doc (showString "(") , prt 0 terms , doc (showString ")")])



