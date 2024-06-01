/* A Bison parser, made by GNU Bison 2.7.  */

/* Bison interface for Yacc-like parsers in C
   
      Copyright (C) 1984, 1989-1990, 2000-2012 Free Software Foundation, Inc.
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.
   
   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_YY_CBU2_H_INCLUDED
# define YY_YY_CBU2_H_INCLUDED
/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     ARRAY = 258,
     ARRAY2 = 259,
     ARRAYNAME = 260,
     STRING = 261,
     STRASSGN = 262,
     LPAREN = 263,
     RPAREN = 264,
     LBRACE = 265,
     RBRACE = 266,
     LBRACKET = 267,
     RBRACKET = 268,
     COMMA = 269,
     ADD = 270,
     SUB = 271,
     MUL = 272,
     DIV = 273,
     MINUS = 274,
     GT = 275,
     LT = 276,
     GE = 277,
     LE = 278,
     EQ = 279,
     NE = 280,
     AND = 281,
     OR = 282,
     NOT = 283,
     FUNC = 284,
     FUNCSTART = 285,
     PARAMS = 286,
     CALL = 287,
     CALLSTART = 288,
     CALLSTMT = 289,
     RETURN = 290,
     IFSTART = 291,
     IFEND = 292,
     ELSEIFSTART = 293,
     IF = 294,
     ELSEIF = 295,
     ELSE = 296,
     WHILE = 297,
     WHILESTART = 298,
     WHILEEND = 299,
     REPEAT = 300,
     BREAK = 301,
     ASSGN = 302,
     ID = 303,
     NUM = 304,
     STMTEND = 305,
     START = 306,
     END = 307,
     ID2 = 308,
     GETCHAR = 309,
     GETINT = 310,
     PUTCHAR = 311,
     PUTINT = 312,
     PUTSTRING = 313,
     PUTARRAY = 314
   };
#endif


#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif

extern YYSTYPE yylval;

#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int yyparse (void *YYPARSE_PARAM);
#else
int yyparse ();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int yyparse (void);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */

#endif /* !YY_YY_CBU2_H_INCLUDED  */
