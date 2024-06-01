%{
#include <string.h>
#include "cbu2.h"
#define MAXSYM	1000
#define	MAXSYMLEN	100
#define LABELSIZE 100
char symtbl[MAXSYM][MAXSYMLEN];
int lineno=1;
int insertsym();
int maxsym=0;
char s[MAXSYMLEN];
int temp;
char stringtemp[MAXSYMLEN];

typedef struct nodeType {
	int token;
	int tokenval;
	struct nodeType *son;
	struct nodeType *brother;
	} Node;

// array의 이름과 array 노드를 저장할 구조체
typedef struct array_info {
	char name[20];
	int size;
	struct array_info* next;
} ArrayInfo;

ArrayInfo* array_info_root = NULL;

ArrayInfo* MakeArrayInfo(char* name, int size);
void AddArrayInfo(char* name, int size);
int findArraySize(char* name);
Node * MakeArrayNode(char * name, int size);

// 함수 관련

// 함수 테이블
typedef struct func_info {
	char name[MAXSYMLEN];
	char local_symtbl[MAXSYM][MAXSYMLEN];
	char label[LABELSIZE]; // 호출위치 (함수의 시작)
	char return_label[LABELSIZE]; // 복귀문 라벨 위치
	int return_cnt;
	char return_tbl[MAXSYM][MAXSYMLEN]; // 복귀위치
	int local_maxsym;
	Node* stmt_list; // 함수가 실행할 문장 리스트
} FUNC_INFO;

extern FUNC_INFO* func_tbl[100];
extern int func_cnt;

// 지역변수 테이블에 추가
extern int AddLocalSym(FUNC_INFO* func, char* sym);

// 함수 테이블에서 함수 찾기
extern FUNC_INFO* FindFuncInfo(char* name);

// 함수 테이블에 추가
extern FUNC_INFO* AddFuncInfo(char* name);

// 함수 구조체 생성
extern FUNC_INFO* MakeFuncInfo(char* name);

// 함수 복귀 위치 추가 후 복귀코드 반환
extern int AddReturn(FUNC_INFO* func, char* label);

// Call 테이블
typedef struct call_info {
	FUNC_INFO* func; // Call하는 함수
	char return_label[LABELSIZE]; // 복귀위치
	int return_code; // 복귀코드
} CALL_INFO;

extern CALL_INFO* call_tbl[100];
extern int call_cnt;

// Call 테이블에 추가
extern CALL_INFO* AddCallInfo(FUNC_INFO* func);

// 이스케이프 문자를 실제 이스케이브 ASCII로 변환
char to_escape(char input) {
	switch (input) {
		case 'n':
			return '\n';
		case 't':
			return '\t';
			break;
		case '\\':
			return '\\';
			break;
		case '\"':
			return '\"';
			break;
		case '\'':
			return '\'';
			break;
		default:
			return input;
	}
}

%}
sp		[ \t]
ws		{sp}+
nl		\n
char	'({sp}|(\\{eletter}|{digit})|{letter}|{digit})'
string	\".*\"
eletter	[A-Za-z]
hletter	[\xb0-\xfe][\xa0-\xfe]
letter	({eletter}|{hletter})
digit	[0-9]
id		{letter}({letter}|{digit})*
comment 	"//".*
%%
{ws}	{/* do nothing */}
{nl}	{lineno++; }
{comment}	{/* do nothing */} 
"+"		{ return(ADD); }
"-"		{ return(SUB); }
"*"		{ return(MUL); }
"/"		{ return(DIV); }
"="		{ return(ASSGN); }
">"		{ return(GT); }
"<"		{ return(LT); }
">="	{ return(GE); }
"<="	{ return(LE); }
"=="	{ return(EQ); }
"!="	{ return(NE); }
"&&"	{ return(AND); }
"||"	{ return(OR); }
"!"		{ return(NOT); }
만약	{ return(IFSTART); }
이면	{ return(IFEND); }
또는	{ return(ELSEIFSTART); }
아니면	{ return(ELSE); }
계속	{ return(WHILESTART); }
"인 동안" { return(WHILEEND); }
"번 반복" { return(REPEAT); }
탈출	{ return(BREAK); }
"("		{ return(LPAREN);}
")"		{ return(RPAREN); }
"{"		{ return(LBRACE); }
"}"		{ return(RBRACE); }
"["		{ return(LBRACKET); }
"]"		{ return(RBRACKET); }
","		{ return(COMMA); }
"문자입력(" { return(GETCHAR); }
"숫자입력("	{ return(GETINT); }
"문자출력(" { return(PUTCHAR); }
"숫자출력("	{ return(PUTINT); }
"문자열출력(" {return(PUTSTRING); }
"함수 "{id}"("(")"|{id}")"|{id}(,{id})*")"); {
	// 함수 선언문
	// 함수 이름 (파라미터1, 파라미터2, ...) 어휘분석
	// 함수 선언문 어휘분석 후 함수 테이블에 추가
	char name[20];
	sscanf(yytext, "함수 %[^'(](", name);
	FUNC_INFO* func = AddFuncInfo(name);
	int func_index = func_cnt-1; // 함수 테이블 인덱스 저장

	// 변수명 추출
	char param_str[30];
	int b = sscanf(yytext, "%*[^'(](%[^)]);", param_str); // 괄호 안 문자열 추출
	if(b != 0) { // 파라미터가 있는 경우
		// 콤마별로 추출
		char param[20];
		const char delimiter[] = ",";
		char* token = strtok(param_str, delimiter);
		while(token != NULL){
			strcpy(param, token);
			AddLocalSym(func, param);
			token = strtok(NULL, delimiter);
		}
	}
}
"함수 "{id}"("(")"|{id}")"|{id}(,{id})*")") {
	// 함수 정의문
	char name[20];
	sscanf(yytext, "함수 %[^'(]", name);

	int i;
	for(i=0; i<func_cnt; i++) {
		if(strcmp(func_tbl[i]->name, name) == 0) {
			break;
		}
	}
	if(i == func_cnt) {
		printf("%s 함수가 선언되지 않았습니다.\n", name);
		yyerror("함수 선언 오류");
		return 0;
	}

	Node* node = MakeNode(FUNC, 0);
	node->tokenval = i; // 함수 테이블 인덱스
	yylval = node;
	return FUNCSTART;
}
{id}"(" {
	// 함수명 (파라미터1, 파라미터2, ...) 어휘분석
	char name[20];
	sscanf(yytext, "%[^'(]", name);
	// printf("함수 %s 호출\n", name);

	FUNC_INFO* func = FindFuncInfo(name);
	if(func == NULL){
		printf("%s 함수가 선언되지 않았습니다.\n", name);
		yyerror("함수 선언 오류");
		return 0;
	}

	// call 테이블에 추가
	CALL_INFO* call = AddCallInfo(func); 
	int info_index = call_cnt-1; // call 테이블 인덱스 저장 

	// func에 복귀위치 추가
	call->return_code = AddReturn(func, call->return_label);

	// call 노드 생성
	yylval = MakeNode(CALL, info_index);
	return CALLSTART;
}
"반환"	{ return(RETURN); }
{char}	{  
	if(yytext[1]=='\\') // 이스케이프 문자 처리
		temp = to_escape(yytext[2]);
	else
		temp = yytext[1];
	yylval=MakeNode(NUM, temp); 
	return(NUM); }
{string}	{ 
	// printf("string : %s\n", yytext);
	// 문자열은 각 문자별로 숫자 토큰으로 변환
	int i;
	Node* node = MakeNode(STRING, 0);

	// 따옴표 처리 위해 1부터 시작
	for(i=1;yytext[i] != '\"';i++){
		// printf("string[%d] : %c\n", i, yytext[i]);
		if(yytext[i] == '\\') { // 이스케이프 문자 처리
			temp = to_escape(yytext[i+1]);
			i++;
		} else {
			temp = yytext[i];
		}

		Node* c = MakeNode(NUM, temp);
		if(node->son == NULL)
			node->son = c;
		else
			MakeListTree(node, c);		
	}
	MakeListTree(node, MakeNode(NUM, '\0')); // 마지막 null 문자 삽입
	node->tokenval = i+1; // STRING 노드에는 문자열의 길이 삽입

	yylval = node;
	return(STRING); 
}
;		{ return(STMTEND); }
시작	{ return(START); }
끝		{ return(END); }
{id}\[ {
	// 배열 원소에 접근하는 경우
	char name[20];
	int size;
	sscanf(yytext, "%[^[]", name);
	size = findArraySize(name);
	if(size == 0){
		printf("%s 는 선언되지않은 배열입니다.\n", name);
		return(0);
	}
	yylval = MakeArrayNode(name, size);
	return(ARRAY);
}
"배열 "{id}\[{digit}+\];	{
	// 배열 선언문을 어휘분석하여 배열 array노드 생성
	char name[20];
    int size;

    // 변수명과 배열 크기 추출
    sscanf(yytext, "배열 %[^[][%d]", name, &size);
	//printf("배열 %s[%d]\n", name, size);
	
	AddArrayInfo(name, size);
}
"배열 "{id} {
	// 배열의 이름 접근시 ArrayNode 생성
	char name[20];
	int size;
	sscanf(yytext, "배열 %s", name);
	size = findArraySize(name);
	if(size == 0){
		printf("%s 는 선언되지않은 배열입니다.\n", name);
		return(0);
	}
	Node* node = MakeArrayNode(name, size);
	node->token = ARRAYNAME;
	yylval = node;
	return ARRAYNAME;
}
{id}	{temp=insertsym(yytext); yylval=MakeNode(ID, temp); return(ID);}
{digit}+		{sscanf(yytext, "%d", &temp); yylval=MakeNode(NUM, temp); return(NUM);}
.		{printf("invalid token %s\n", yytext); }
%%

int insertsym(s)
char *s;
{
int i;
	for(i=0;i<maxsym; i++) {
		if(strcmp(s, symtbl[i])==0) return(i);
	}
	if (i<MAXSYM-1) {
		strcpy(symtbl[maxsym],s);
		maxsym++;
		return(maxsym-1);
		}
	else
		{printf("symbol table overflow\n");}
	return(0); 
}

int findArraySize(char* name)
{
	ArrayInfo* cursor = array_info_root;
	while(cursor != NULL){
		if(strcmp(cursor->name, name) == 0)
			return cursor->size;
		cursor = cursor->next;
	}
	return 0;
}

void AddArrayInfo(char* name, int size)
{
	ArrayInfo* cursor, new_info;
	if(array_info_root == NULL){
		array_info_root = MakeArrayInfo(name, size);
		return;
	}
	
	cursor = array_info_root;
	while(cursor->next!=NULL) 
		cursor = cursor->next;
		
	cursor->next = MakeArrayInfo(name, size);
}

ArrayInfo* MakeArrayInfo(char* name, int size)
{
	ArrayInfo* array_info = (ArrayInfo*)malloc(sizeof(ArrayInfo));
	strcpy(array_info->name,name);
	array_info->size = size;
	array_info->next = NULL;
	return array_info;
}

// 새로운 Array Node를 만들고 + 각 배열 원소를 symboltbl에 추가
// 아래와 같은 구조의 노드를 만듦
// root : array(a) ($$ = NULL)
// son  : ID($$ = a0) - ID($$ = a1) - ID($$ = a2) - ID($$ = a3) ... 
Node * MakeArrayNode(char * name, int size) 
{
	Node * cell;
	Node * root;
	int t;
	
	root = MakeNode(ARRAY,size);
	
	for(int i=0;i<size;i++){
		sprintf(stringtemp, "%s%d\0", name,i);
		t = insertsym(stringtemp); // symbol_tbl에 배열 원소 추가
		cell = MakeNode(ID,t);

		if(root->son == NULL) // cell을 자식노드르 추가
			root->son = cell;
		else 
			MakeListTree(root,cell); // cell을 자식노드의 형제노드로 추가
	}
	
	return root;
}

yywrap() {}