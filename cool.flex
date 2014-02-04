/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

#define RETURN_ERROR(msg) \
	do { \
	   cool_yylval.error_msg = msg; \
	   return ERROR; \
	}while (0)
void ASSEMBLE(char c) {\
 *string_buf_ptr++ = c; \
}

int comment_level = 0;
%}

/*
 * Define names for regular expressions here.
 */



DARROW          =>

%x COMMENT STRING
%%

 /*
  *  Nested comments
  */

"--".*					;
"*)"					{RETURN_ERROR("Unmatched *)");}
<INITIAL,COMMENT>"(*"			{
						BEGIN(COMMENT);
						++comment_level;	
					}
<COMMENT>{
	"*"+")"				{
						if (--comment_level < 1)
						BEGIN(INITIAL);
					}
	<<EOF>>				{
						BEGIN(INITIAL);
						RETURN_ERROR("EOF in comment");
					}
	\n				++curr_lineno;
	\\.				;
	[^(*\\\n]*			;
	.				;						
}

 /*
  *  The multiple-character operators.
  */

"@"					{return '@';}
"*"					{return '*';}
"/"					{return '/';}
"+"					{return '+';}
"-"					{return '-';}
"<"					{return '<';}
";"					{return ';';}
","					{return ',';}
"("					{return '(';}
")"					{return ')';}
":"					{return ':';}
"~"					{return '~';}
"{" 					{return '{';}
"}" 					{return '}';}
"="					{return '=';}
"."					{return '.';}
{DARROW}				{return (DARROW); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

[cC][lL][aA][sS][sS]			{return CLASS;}//class
[eE][lL][sS][eE]     			{return ELSE;}//else
[fF][iI]				{return FI;}//fi
[iI][fF]				{return IF;}//if
[iI][nN]				{return IN;}//in
[iI][nN][hH][eE][rR][iI][tT][sS]	{return INHERITS;}//inherits
[lL][eE][tT]				{return LET;}//let
[lL][oO][oO][pP]			{return LOOP;}//loop
[pP][oO][oO][lL]			{return POOL;}//pool
[tT][hH][eE][nN]			{return THEN;}//then
[wW][hH][iI][lL][eE]			{return WHILE;}//while
[cC][aA][sS][eE]			{return CASE;}//case
[eE][sS][aA][cC]			{return ESAC;}//esac
[oO][fF]				{return OF;}//of
[nN][eE][wW]				{return NEW;}//new
[iI][sS][vV][oO][iI][dD]		{return ISVOID;}//isvoid
[f][aA][lL][sS][eE]			{
					cool_yylval.boolean = false; 
					return BOOL_CONST;
					}//false
[t][rR][uU][eE]				{
					cool_yylval.boolean = true;
					return BOOL_CONST;
					}//true//BOOL_CONST

"<-"					{return ASSIGN;}//ASSIGN
[nN][oO][tT]				{return NOT;}//not
"<="					{return LE;}//LE

[A-Z][a-zA-Z0-9_]*			{	cool_yylval.symbol = idtable.add_string(yytext);
						return TYPEID;}//TYPEID
[a-z][a-zA-Z0-9_]*			{	cool_yylval.symbol = idtable.add_string(yytext);
						return OBJECTID;}//OBJECTID
[0-9]+					{	cool_yylval.symbol = inttable.add_string(yytext);
						return INT_CONST;}//INT_CONST					

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\"					{
						string_buf_ptr = string_buf;
						BEGIN(STRING);
					}
<STRING>{
	\"			{
						*string_buf_ptr = '\0';
						BEGIN(INITIAL);
						cool_yylval.symbol = stringtable.add_string(string_buf);
						return STR_CONST;
					}
	\+0				{
						BEGIN(INITIAL);
						//RETURN_ERROR("String contains null character");
						return ERROR;
					}
	<<EOF>>				{
						BEGIN(INITIAL);
						RETURN_ERROR("EOF in string constant");
					}
	\n				{
						BEGIN(INITIAL);
						RETURN_ERROR("Unterminated string constant");
					}
	\\				{
						
					}
	\\b				{
						ASSEMBLE('\b');
					}
	\\f				{
						ASSEMBLE('\f');
					}
	\\t				{
						ASSEMBLE('\t');
					}
	\\n				{
						ASSEMBLE('\n');
					}
	\\\n				{
						++curr_lineno;
						ASSEMBLE('\n');
					}
	\\.				{
						ASSEMBLE(yytext[1]);
					}
	[^\\\n\0\"]+			{
						if (string_buf_ptr + yyleng \
						    > &(string_buf[MAX_STR_CONST-1])) {
						    RETURN_ERROR("String constant too long");    
						}
						strcpy(string_buf_ptr, yytext);
						string_buf_ptr += yyleng;
					}
}


[ \t\r\f\v]				;
\n					curr_lineno ++;
.					RETURN_ERROR(yytext);
%%
