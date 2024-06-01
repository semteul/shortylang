%{
/*
TODO : 
* define으로 label 크기 정하기
* 함수들 선언문 쓰기(labelgen, WHILETree, IFTree 등)
* DFSTree 순회 좀 더 깔끔한 코드로
*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define DEBUG	0

#define	 MAXSYM	1000
#define	 MAXSYMLEN	100
#define	 MAXTSYMLEN	15
#define	 MAXTSYMBOL	MAXSYM/2

#define LABELSIZE 100

#define STMTLIST 500

typedef struct nodeType {
	int token;
	int tokenval;
	struct nodeType *son;
	struct nodeType *brother;
	} Node;

#define YYSTYPE Node*
	
int tsymbolcnt=0;
int errorcnt=0;

FILE *yyin;
FILE *fp;

char temp_char[1000];

extern char symtbl[MAXSYM][MAXSYMLEN];
extern int maxsym;
extern int lineno;

void DFSTree(Node*);
Node * MakeOPTree(int, Node*, Node*);
Node * MakeNode(int, int);
Node * MakeListTree(Node*, Node*);
void codegen(Node* );
void prtcode(int, int);

void	dwgen();
int	gentemp();
void	assgnstmt(int, int);
void	numassgn(int, int);
void	addstmt(int, int, int);
void	substmt(int, int, int);
int		insertsym(char *);

char * while_stack[500]; // while문의 out 라벨이 쌓이는 스택, break문을 위해 쓰임
int while_stack_top = 0; // while_stack의 top
void while_stack_push(char* label) {
	while_stack[while_stack_top++] = label;
}
char* while_stack_pop() {
	if(while_stack_top == 0) return NULL;
	return while_stack[--while_stack_top];
}


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


FUNC_INFO* func_tbl[100];
int func_cnt = 0;

int AddLocalSym(FUNC_INFO* func, char* sym);
FUNC_INFO* FindFuncInfo(char* name);
FUNC_INFO* AddFuncInfo(char* name);
FUNC_INFO* MakeFuncInfo(char* name);

// 지역변수 테이블에 추가
int AddLocalSym(FUNC_INFO* func, char* sym) {
	int i;
	for(i=0; i < (func->local_maxsym); i++) {
		if(strcmp(func->local_symtbl[i], sym) == 0) {
			return i;
		}
	}
	func->local_maxsym++;
	strcpy(func->local_symtbl[i], sym);
	return i;
}

// 함수 테이블에서 함수 찾기
FUNC_INFO* FindFuncInfo(char* name) {
	int i;
	for(i=0; i<func_cnt; i++) {
		if(strcmp(func_tbl[i]->name, name) == 0) {
			return func_tbl[i];
		}
	}
	return NULL;
}

// 함수 테이블에 추가
FUNC_INFO* AddFuncInfo(char* name) {
	FUNC_INFO* func_info = MakeFuncInfo(name);
	
	func_tbl[func_cnt++] = func_info;
	return func_info;
}

// 함수 구조체 생성
FUNC_INFO* MakeFuncInfo(char* name) {
	FUNC_INFO* func_info = (FUNC_INFO*)malloc(sizeof(FUNC_INFO));
	// func->name 에 name 지정
	strcpy(func_info->name, name);
	func_info->local_maxsym = 0;
	func_info->return_cnt = 0;
	func_info->stmt_list = NULL;
	
	char label[100];
	labelgen(label);
	strcpy(func_info->label, label);
	labelgen(label);
	strcpy(func_info->return_label, label);
	return func_info;
}

// 함수 복귀위치 추가
int AddReturn(FUNC_INFO* func, char* label) {
	strcpy(func->return_tbl[func->return_cnt++], label);
	return func->return_cnt-1;
}

// Call 테이블
typedef struct call_info {
	FUNC_INFO* func; // Call하는 함수
	char return_label[LABELSIZE]; // 복귀위치
	int return_code; // 복귀코드
} CALL_INFO;

CALL_INFO* call_tbl[100];
int call_cnt = 0;

// Call 테이블에 추가
CALL_INFO* AddCallInfo(FUNC_INFO* func) {
	CALL_INFO* call_info = (CALL_INFO*)malloc(sizeof(CALL_INFO));
	call_info->func = func;
	char label[100];
	labelgen(label);
	strcpy(call_info->return_label, label);
	call_tbl[call_cnt++] = call_info;
	return call_info;
}


// 현재 파싱중인 stmt_list를 실행하는 함수
FUNC_INFO* current_func = NULL;

extern int insertsym(char *s);

// 현재 파싱중인 함수의 지역변수로 변환시키기, 만약 지역변수가 아니면 그대로 반환
int function_local_sym(int symid) {
	if(current_func == NULL) { // 전역공간인경우
		return symid;
	}
	for(int i=0; i<current_func->local_maxsym; i++) {
		// 만약 지역변수라면
		if(strcmp(current_func->local_symtbl[i], symtbl[symid]) == 0) {
			char local_sym[MAXSYMLEN];
			sprintf(local_sym, "FUNC%s%s", current_func->name, symtbl[symid]);
			int i = insertsym(local_sym);
			return i;
		}
	}
	return symid; // 지역공간에 있지만, 지역변수가 아닌 경우
}


%}

%token ARRAY ARRAY2 ARRAYNAME STRING STRASSGN
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET COMMA
%token ADD SUB MUL DIV MINUS
%token GT LT GE LE EQ NE
%token AND OR NOT
%token FUNC FUNCSTART PARAMS CALL CALLSTART CALLSTMT RETURN
%token IFSTART IFEND ELSEIFSTART IF ELSEIF ELSE WHILE WHILESTART WHILEEND REPEAT BREAK
%token ASSGN ID NUM STMTEND START END ID2
%token GETCHAR GETINT PUTCHAR PUTINT PUTSTRING PUTARRAY

%left ADD SUB MUL DIV

%%
program	: START stmt_list END	{ if (errorcnt==0) {codegen($2); dwgen();} }
		| START func_list stmt_list END { if (errorcnt==0) {codegen($3); codegen($2); dwgen();} }
		;

func_list 	: func_list func_init { $$ = MakeListTree($1, $2); }
			| func_init { $$ = MakeListTree(NULL, $1); }
			; 

func_init : FUNCSTART LBRACE stmt_list RBRACE { Node* node = $1; node->son = $3; $$ = node;}
		;

stmt_list: 	stmt_list stmt 	{$$=MakeListTree($1, $2);}
		|	stmt			{$$=MakeListTree(NULL, $1);}
		| 	error STMTEND	{ errorcnt++; yyerrok;}
		;

stmt	: 	ID ASSGN expr STMTEND	{ $1->token = ID2; $$=MakeOPTree(ASSGN, $1, $3); }
		|	array_element ASSGN expr STMTEND	{ $1->token = ARRAY2; $$=MakeOPTree(ASSGN, $1, $3); }
		|	ARRAYNAME ASSGN STRING STMTEND { $$ = MakeOPTree(STRASSGN, $1, $3); }
		|	branch_stmt
		|	while_stmt
		|	repeat_stmt
		|	break_stmt
		|	RETURN expr STMTEND { $$ = MakeOPTree(RETURN, $2, NULL); }
		|	call_expr STMTEND { Node* node = $1; node->token = CALLSTMT; $$ = node; }
		|	PUTCHAR expr RPAREN STMTEND { $$ = MakeOPTree(PUTCHAR, $3, NULL); }
		|	PUTINT expr RPAREN STMTEND { $$ = MakeOPTree(PUTINT, $3, NULL); } 
		|	PUTSTRING STRING RPAREN STMTEND { $$ = MakeOPTree(PUTSTRING, $3, NULL);}
		|	PUTSTRING ARRAYNAME RPAREN STMTEND { $$ = MakeOPTree(PUTARRAY, $3, NULL); }
		;

break_stmt : BREAK STMTEND { $$ = MakeNode(BREAK, 0);}
		;

branch_stmt  	: if_stmt
				| if_stmt else_stmt { $$=MakeListTree($1, $2); }
				| if_stmt elif_stmt { $$=MakeListTree($1, $2); }

elif_stmt		: else_if_stmt
				| else_if_stmt else_stmt { $$=MakeListTree($1, $2); }
				| else_if_stmt elif_stmt { $$=MakeListTree($1, $2); }

if_stmt			: IFSTART expr IFEND LBRACE stmt_list RBRACE { $$=MakeOPTree(IF, $2, $5); }

else_if_stmt 	: ELSEIFSTART expr IFEND LBRACE stmt_list RBRACE { $$=MakeOPTree(IF, $2, $5); }

else_stmt 		: ELSE LBRACE stmt_list RBRACE { $$=$3; }

while_stmt 		: WHILESTART expr WHILEEND LBRACE stmt_list RBRACE { $$ = MakeOPTree(WHILE, $2, $5); }
				;

repeat_stmt		: expr REPEAT LBRACE stmt_list RBRACE { $$ = MakeOPTree(REPEAT, $1, $4);}
				;


expr	: expr AND expr3 { $$=MakeOPTree(AND, $1, $3); }
		| expr OR expr3 { $$=MakeOPTree(OR, $1, $3); }
		| expr3
		;

expr3	:	expr2 EQ expr2 { $$=MakeOPTree(EQ, $1, $3); }
		|	expr2 NE expr2 { $$=MakeOPTree(NE, $1, $3); }
		|	expr2 GT expr2 { $$=MakeOPTree(GT, $1, $3); }
		|	expr2 LT expr2 { $$=MakeOPTree(LT, $1, $3); }
		|	expr2 GE expr2 { $$=MakeOPTree(GE, $1, $3); }
		|	expr2 LE expr2 { $$=MakeOPTree(LE, $1, $3); }
		|	expr2
		;

expr2	: 	expr2 ADD expr1	{ $$=MakeOPTree(ADD, $1, $3); }
		|	expr2 SUB expr1	{ $$=MakeOPTree(SUB, $1, $3); }
		|	expr1
		;

expr1	:	expr1 MUL expr0	{ $$=MakeOPTree(MUL, $1, $3); }
		|	expr1 DIV expr0	{ $$=MakeOPTree(DIV, $1, $3); }
		|	expr0
		;

expr0	:	SUB term { $$=MakeOPTree(MINUS, $2, NULL); }
		|	NOT term { $$=MakeOPTree(NOT, $2, NULL); }
		|	term
		;

term	:	ID							{ /* ID node is created in lex */ }
		| 	array_element				{ $$ = $1; }
		|	NUM							{ /* NUM node is created in lex */ }
		|	LPAREN expr RPAREN 			{ $$ = $2; }
		|	call_expr					{ $$ = $1; }
		|	GETCHAR RPAREN		{ $$ = MakeNode(GETCHAR,0); }
		|	GETINT RPAREN		{ $$ = MakeNode(GETINT,0);}
		;

call_expr 	: call RPAREN { $$ = $1; argumentCheck($1); }
			;

call 		: call COMMA expr { $$ = MakeListTree($1, $3); /* , 파라메터...  */ }
			| CALLSTART expr { Node* node = $1; node->son = $2; $$ = node; /* 파라메터 있는 호출*/ }
			| CALLSTART { $$ = $1; /* 매개변수 없는 호출 */ }
			;

array_element   :	ARRAY expr RBRACKET	{ 
				// son 맨 앞에다 expr 붙이기
				Node* node = $1;
				Node* expr = $2;
				expr->brother = node->son;
				node->son = expr;
			}
		;

%%
int main(int argc, char *argv[]) 
{
	printf("\n스택머신용 프로그래밍 언어 '짧은글' 컴파일러 v0.1\n");
	printf("충북대학교 소프트웨어학부 김민석 (2022078073) 개발 - 2024.05\n\n");
	
	if (argc == 2)
		yyin = fopen(argv[1], "r");
	else {
		printf("이용법: .cg 파일을 입력으로 하면\n'a.asm' 어셈블리 파일 생성\n");
		return(0);
		}
		
	fp=fopen("a.asm", "w");
	
	yyparse();
	
	fclose(yyin);
	fclose(fp);

	if (errorcnt==0) 
		{ printf("컴파일성공! 어셈블리코드는 'a.asm'에 있습니다.\n");}
}

yyerror(s)
char *s;
{
	errorcnt++;
	printf("%s (line %d)\n", s, lineno);
}


Node * MakeOPTree(int op, Node* operand1, Node* operand2)
{
Node * newnode;

	newnode = (Node *)malloc(sizeof (Node));
	newnode->token = op;
	newnode->tokenval = op;
	newnode->son = operand1;
	newnode->brother = NULL;
	operand1->brother = operand2;
	return newnode;
}

Node * MakeNode(int token, int operand)
{
Node * newnode;

	newnode = (Node *) malloc(sizeof (Node));
	newnode->token = token;
	newnode->tokenval = operand; 
	newnode->son = newnode->brother = NULL;
	return newnode;
}

Node * MakeListTree(Node* operand1, Node* operand2)
{
Node * newnode;
Node * node;

	if (operand1 == NULL){
		newnode = (Node *)malloc(sizeof (Node));
		newnode->token = newnode-> tokenval = STMTLIST;
		newnode->son = operand2;
		newnode->brother = NULL;
		return newnode;
		}
	else {
		node = operand1->son;
		while (node->brother != NULL) node = node->brother;
		node->brother = operand2;
		return operand1;
		}
}

void codegen(Node * root)
{
	DFSTree(root);
	fprintf(fp, "HALT\n");
}

void CMPTree(Node * n)
{
	fprintf(fp, "$ -- START OF COMPARISON -- \n");
	DFSTree(n->son);
	prtcode(n->token, n->tokenval);
	DFSTree(n->brother);
	fprintf(fp, "$ -- END OF COMPARISON -- \n");
}

/*
	LABEL else_label
	조건문 실행, 실행 결과 0 또는 1 push
	GOFALSE else_label
	if_stmt
	GOTO out
	LABEL else_label
	else_stmt
	LABEL out
*/
// 노드 구조
// IF (root)
// cmp_stmt - if_stmt - else_stmt
void IFTree(Node * n) 
{
	char else_label[LABELSIZE];
	char out[LABELSIZE];
	labelgen(else_label);
	labelgen(out);

	fprintf(fp, "$ -- START OF IF -- \n");

	Node* cmp_stmt = n->son;
	Node* if_stmt = n->son->brother;
	Node* else_stmt = n->son->brother->brother;

	// 아래와 같이 순회하는 이유 : brother를 순회하기 전에 처리해주어야 할 부분이 있음
	DFSTree(cmp_stmt->son); // 조건문 순회
	prtcode(cmp_stmt->token, cmp_stmt->tokenval); // 조건문 처리

	fprintf(fp, "GOFALSE %s\n",else_label); // 조건문이 거짓인 경우, else로
	DFSTree(if_stmt->son); // if 실행
	prtcode(if_stmt->token, if_stmt->tokenval); // if문 처리
	fprintf(fp, "GOTO %s\n", out); // if문 끝나면 out으로

	fprintf(fp, "LABEL %s\n", else_label);
	DFSTree(else_stmt); // else 실행
	fprintf(fp, "LABEL %s\n", out);

	fprintf(fp, "$ -- END OF IF -- \n"); 

	DFSTree(n->brother); // 형제 노드 순회
}

/*
	LABEL loop
	조건문 실행, 실행 결과 0 또는 1 push
	GOFALSE out
	stmt_list
	GOTO loop
	LABEL out
*/
// 노드 구조
// WHILE (root)
// cmp_stmt - stmt_list
void WHILETree(Node *n)
{
	char loop[LABELSIZE];
	char out[LABELSIZE];
	labelgen(loop);
	labelgen(out);

	fprintf(fp, "$ -- START OF WHILE -- \n");
	// while stack push
	while_stack_push(out);

	Node* cmp_stmt = n->son;
	Node* stmt_list = n->son->brother;

	// 아래와 같이 순회하는 이유 : brother를 순회하기 전에 처리해주어야 할 부분이 있음
	fprintf(fp, "LABEL %s\n", loop);
	DFSTree(cmp_stmt->son); // 조건문 순회
	prtcode(cmp_stmt->token, cmp_stmt->tokenval); // 조건문 처리

	fprintf(fp, "GOFALSE %s\n", out);

	DFSTree(stmt_list); // stmt_list 순회

	fprintf(fp, "GOTO %s\n",loop);
	fprintf(fp, "LABEL %s\n", out);

	fprintf(fp, "$ -- END OF WHILE -- \n");
	// while_stack pop
	while_stack_pop();
	DFSTree(n->brother); // 형제 노드 순회
}

void BREAKTree(Node *n)
{
	fprintf(fp, "$ -- START OF BREAK -- \n");
	char* out = while_stack_pop();
	while_stack_push(out);
	if(out == NULL) {
		printf("break문은 while문 내에서만 사용할 수 있습니다.\n");
		return;
	}
	fprintf(fp, "GOTO %s\n", out);
	fprintf(fp, "$ -- END OF BREAK -- \n");
	DFSTree(n->brother); // 형제 노드 순회
}

/*
	반복할 숫자 실행, 반복할 숫자 push될 것
	LABEL repeat
	PUSH 1
	-
	COPY
	GOMINUS out
	stmt_list
	GOTO repeat
	LABEL out
*/
// 노드 구조
// REPEAT (root)
// 반복할 숫자 - stmt_list
void REPEATTree(Node *n)
{
	char repeat[LABELSIZE];
	char out[LABELSIZE];
	labelgen(repeat);
	labelgen(out);

	fprintf(fp, "$ -- START OF REPEAT -- \n");

	Node* repeat_num = n->son;
	Node* stmt_list = n->son->brother;

	// 아래와 같이 순회하는 이유 : brother를 순회하기 전에 처리해주어야 할 부분이 있음
	DFSTree(repeat_num->son); // 반복할 숫자 순회
	prtcode(repeat_num->token, repeat_num->tokenval); // 반복할 숫자 처리

	fprintf(fp, "LABEL %s\n", repeat);
	fprintf(fp, "PUSH 1\n");
	fprintf(fp, "-\n");
	fprintf(fp, "COPY\n");
	fprintf(fp, "GOMINUS %s\n", out);

	DFSTree(stmt_list); // stmt_list 순회

	fprintf(fp, "GOTO %s\n", repeat);
	fprintf(fp, "LABEL %s\n", out);
	fprintf(fp, "POP\n");

	fprintf(fp, "$ -- END OF REPEAT -- \n");
	DFSTree(n->brother); // 형제 노드 순회
}

void ArrayTree(int token, Node * n) {
	fprintf(fp, "$ -- START OF ARRAY -- \n");

	Node* cursor = n->son->brother;
	int i=0;
	char label[1000][LABELSIZE];
	char out[LABELSIZE];

	// label 생성
	while(cursor != NULL) {
		cursor = cursor->brother;
		labelgen(label[i++]);
	}
	labelgen(out);

	// expr 실행
	Node* expr = n->son;
	DFSTree(expr->son);
	prtcode(expr->token, expr->tokenval);

	// 비교
	i=0;
	cursor = n->son->brother;
	while(cursor != NULL) {
		
		fprintf(fp,"$ handling %s[%d]\n",symtbl[cursor->tokenval],i);
		
		fprintf(fp,"COPY\n");
		fprintf(fp,"PUSH %d\n",i);
		fprintf(fp,"-\n");
		fprintf(fp,"GOFALSE %s\n",label[i++]);
		
		cursor = cursor->brother;
	}
	
	// 인덱스가 범위 밖인 경우 첫번째 인덱스로 설정
	fprintf(fp, "POP\n");
	if(token == ARRAY) {
		fprintf(fp, "RVALUE %s\n",symtbl[n->son->brother->tokenval]);
	} else {
		fprintf(fp, "LVALUE %s\n",symtbl[n->son->brother->tokenval]);
	}
	fprintf(fp, "GOTO %s\n",out);

	i=0;
	cursor = n->son->brother;
	while(cursor != NULL) {
		fprintf(fp,"LABEL %s\n",label[i++]);
		fprintf(fp, "POP\n"); // PUSH 해주었던 인덱스 POP
		if(token == ARRAY){
			fprintf(fp,"RVALUE %s\n",symtbl[cursor->tokenval]);
		} else {
			fprintf(fp,"LVALUE %s\n",symtbl[cursor->tokenval]);
		}
		fprintf(fp,"GOTO %s\n",out);
		cursor = cursor->brother;
	}
	fprintf(fp,"LABEL %s\n",out);

	fprintf(fp, "$ -- END OF ARRAY -- \n");
	DFSTree(n->brother); // 형제 노드 순회
}

void ANDTree(Node* n)
{
	char out[LABELSIZE];
	char push0[LABELSIZE];
	labelgen(out);
	labelgen(push0);
	Node* left = n->son;
	Node* right = n->son->brother;

	DFSTree(left->son);
	prtcode(left->token, left->tokenval);

	fprintf(fp,"GOFALSE %s\n",push0);

	DFSTree(right->son);
	prtcode(right->token, right->tokenval);

	fprintf(fp,"GOFALSE %s\n",push0);
	fprintf(fp,"PUSH 1\n");
	fprintf(fp,"GOTO %s\n",out);
	fprintf(fp,"LABEL %s\n",push0);
	fprintf(fp,"PUSH 0\n");
	fprintf(fp,"LABEL %s\n",out); // 나가기

	DFSTree(n->brother); // 형제 노드 순회
}

void ORTree(Node* n)
{
	char out[LABELSIZE];
	char push1[LABELSIZE];
	labelgen(out);
	labelgen(push1);
	Node* left = n->son;
	Node* right = n->son->brother;

	DFSTree(left->son);
	prtcode(left->token, left->tokenval);

	fprintf(fp,"GOTRUE %s\n",push1);

	DFSTree(right->son);
	prtcode(right->token, right->tokenval);

	fprintf(fp,"GOTRUE %s\n",push1);
	fprintf(fp,"PUSH 0\n");
	fprintf(fp,"GOTO %s\n",out);
	fprintf(fp,"LABEL %s\n",push1);
	fprintf(fp,"PUSH 1\n");
	fprintf(fp,"LABEL %s\n",out); // 나가기

	DFSTree(n->brother); // 형제 노드 순회
}

void NOTTree(Node* n)
{
	char push0[LABELSIZE];
	char out[LABELSIZE];
	labelgen(push0);
	labelgen(out);

	DFSTree(n->son);
	prtcode(n->token, n->tokenval);
	
	fprintf(fp,"GOFALSE %s\n",push0);
	fprintf(fp,"PUSH 0\n");
	fprintf(fp,"GOTO %s\n",out);
	fprintf(fp,"LABEL %s\n",push0);
	fprintf(fp,"PUSH 1\n");
	fprintf(fp,"LABEL %s\n",out);

	DFSTree(n->brother); // 형제 노드 순회
}

// 함수 argument가 올바르게 되었는가 체크
void argumentCheck(Node* call) {
	CALL_INFO* call_info = call_tbl[call->tokenval]; // call info 얻어오기
	FUNC_INFO* func_info = call_info->func; // 함수 정보 
	
	Node* arg = call->son; // argument 노드
	int count = 0;
	while(arg != NULL) {
		count++;
		arg = arg->brother;
	}
	if(count != func_info->local_maxsym) {
		printf("넘기는 인자의 개수 : %d, 함수의 파라미터 개수 : %d\n", count, func_info->local_maxsym);
		yyerror("매개변수 개수 불일치");
	}
}

void DFSTree(Node * n)
{
	if (n==NULL) return;
	if (n->token == MINUS) {
		fprintf(fp,"PUSH 0\n"); // 0 push
		DFSTree(n->son); // expr 순회
		fprintf(fp,"-\n"); // 음수화
		DFSTree(n->brother);
		return;
	}
	if (n->token == IF){
		IFTree(n);
		return;
	}
	if (n->token == WHILE) {
		WHILETree(n);
		return;
	}
	if (n->token == BREAK) {
		BREAKTree(n);
		return;
	}
	if (n->token == REPEAT) {
		REPEATTree(n);
		return;
	}
	switch(n->token) {
		case EQ:
		case NE:
		case GT:
		case LT:
		case GE:
		case LE:
			CMPTree(n);
			return;
	}
	if (n->token == AND) {
		ANDTree(n);
		return;
	}
	if (n->token == OR) {
		ORTree(n);
		return;
	}
	if (n->token == NOT) {
		NOTTree(n);
		return;
	}
	if (n->token == ARRAY) {
		ArrayTree(ARRAY, n);
		return;
	}
	if (n->token == ARRAY2) {
		ArrayTree(ARRAY2, n);
		return;
	}
	if (n->token == STRASSGN) {
		char* label;
		char c;
		Node* array = n->son;
		Node* str = n->son->brother;

		Node* array_element = array->son;
		Node* str_element = str->son;

		while(array_element != NULL && str_element != NULL) {
			c = str_element->tokenval;
			label = symtbl[array_element->tokenval];
			if(c=='\0') {
				break;
			}

			fprintf(fp, "LVALUE %s\n", label);
			fprintf(fp, "PUSH %d\n", c);
			fprintf(fp, ":=\n");

			array_element = array_element->brother;
			str_element = str_element->brother;
		}
		fprintf(fp, "LVALUE %s\n", label);
		fprintf(fp, "PUSH 0\n");
		fprintf(fp, ":=\n");
		DFSTree(n->brother);
		return;
	}
	if(n->token == PUTSTRING || n->token == PUTARRAY) {
		char out[LABELSIZE];
		Node* str = n->son;
		Node* str_element = str->son;
		char c;

		labelgen(out);
		while(str_element != NULL) {
			c = str_element->tokenval;
			if(n->token == PUTSTRING){
				if(c == '\0')
					break;
				fprintf(fp, "PUSH %d\n", c); // 한글 출력 위해 unsigned로 push
			} else {
				fprintf(fp, "RVALUE %s\n", symtbl[str_element->tokenval]);
				fprintf(fp, "COPY\n");
				fprintf(fp, "GOFALSE %s\n",out);
			}
			fprintf(fp, "OUTCH\n");
			str_element = str_element->brother;
		}
		fprintf(fp, "LABEL %s\n", out);
		DFSTree(n->brother);
		return;
	}
	if(n->token == RETURN) {
		if(current_func == NULL) {
			printf("전역공간에서 return문은 사용할 수 없습니다.\n");
			yyerror("전역공간에서 return문 사용");
			return;
		}
		FUNC_INFO* func = current_func;

		// 복귀값 저장
		fprintf(fp, "LVALUE FUNCret\n");
		DFSTree(n->son);
		fprintf(fp, ":=\n");
		fprintf(fp, "GOTO %s\n", func->return_label);
		DFSTree(n->brother);
		return;
	}
	if(n->token == FUNC) {
		char return_label[LABELSIZE];
		FUNC_INFO* func = func_tbl[n->tokenval]; // func info 얻어오기
		fprintf(fp, "$ -- START OF FUNCTION %s --\n", func->name);
		fprintf(fp, "LABEL %s\n", func->label); // 함수 시작 라벨

		current_func = func; // 지역변수 변환 & 다른 함수 호출시 지역변수 push 하는 기능을 위해
		DFSTree(n->son); // 함수 실행문 출력
		current_func = NULL;


		fprintf(fp, "PUSH 0\n"); // 복귀값이 없을 때
		fprintf(fp, "LVALUE FUNCret\n"); // 복귀값이 없을 때
		fprintf(fp, ":=\n"); // 복귀값이 없을 때
		// 복귀 처리 시작
		fprintf(fp, "LABEL %s\n", func->return_label);
		for(int i=0; i<(func->return_cnt); i++) {
			fprintf(fp, "COPY\n");
			fprintf(fp, "PUSH %d\n", i);
			fprintf(fp, "-\n");
			fprintf(fp, "GOFALSE %s\n", func->return_tbl[i]);
		}

		fprintf(fp, "POP\n");
		fprintf(fp, "$ -- END OF FUNCTION %s --\n", func->name);
		DFSTree(n->brother); 
		return;
	}
	if(n->token == CALL || n->token == CALLSTMT) {
		
		CALL_INFO* call_info = call_tbl[n->tokenval]; // call info 얻어오기
		FUNC_INFO* func = call_info->func; // 함수 정보
		Node* arg = n->son; // argument 노드

		fprintf(fp, "$ -- START OF CALL %s --\n", func->name);
		
		// call하기 전에, 만약 call이 함수 안에서 불리고 있다면, 지역변수를 push한다.
		if(current_func != NULL) {
			for(int i=0;i<(current_func->local_maxsym);i++) {
				get_global_label(current_func,i,temp_char);
				fprintf(fp, "LVALUE %s\n", temp_char);
				fprintf(fp, "RVALUE %s\n", temp_char);
			}
		} 
		
		fprintf(fp, "PUSH %d\n", call_info->return_code); // 복귀 코드 push
		
		// 인자를 함수 파라미터에 넣기
		int i=0;
		arg = n->son;
		while(arg != NULL) {
			get_global_label(func,i++,temp_char);
			fprintf(fp, "LVALUE %s\n", temp_char);
			DFSTree(arg->son); // argument 순회
			prtcode(arg->token, arg->tokenval); // argument 처리
			fprintf(fp, ":=\n");
			
			arg = arg->brother;
		}
		
		fprintf(fp, "GOTO %s\n", func->label); // 함수 호출

		fprintf(fp, "LABEL %s\n", call_info->return_label); // 복귀 라벨
		fprintf(fp, "POP\n"); // 함수 호출 후 복귀 코드 pop
		
		// 만약 call이 함수 안에서 불리고 있다면, push했던 지역변수를 다시 저장한다.
		if(current_func != NULL) {
			for(int i=(current_func->local_maxsym)-1;i>=0;i--) {
				fprintf(fp, ":=\n");
			}
		}

		if(n->token != CALLSTMT) {
			fprintf(fp, "RVALUE FUNCret\n"); // 복귀값 PUSH
		}

		fprintf(fp, "$ -- END OF CALL %s --\n", func->name);
		DFSTree(n->brother);
		
		return;
	}
	
	DFSTree(n->son);
	prtcode(n->token, n->tokenval);
	DFSTree(n->brother);
}

void get_global_label(FUNC_INFO* func, int i, char* label) {
	//printf("함수 %s의 심볼 %s", func->name, func->local_symtbl[i]);
	sprintf(label, "FUNC%s%s", func->name, func->local_symtbl[i]);
}

void labelgen(char* label)
{
	static char generated_label[LABELSIZE] = {'L','a', '\0'};

	int i=1;
	while(1) {
		if(generated_label[i] == '\0') {
			generated_label[i] = 'a';
			generated_label[i+1] = '\0';
		}
		if(generated_label[i] == 'z') {
			generated_label[i] = 'A';
			i++;
		} else if(generated_label[i] == 'Z') {
			generated_label[i] = 'a';
			i++;
		} else {
			generated_label[i]++;
			break;
		}
	}   

	strcpy(label, generated_label);
}

void prtcmp(int token, int val) {
	char push0[LABELSIZE];
	char push1[LABELSIZE];
	char out[LABELSIZE];

	// 분기문에서 사용할 라벨 처리 & 비교
	labelgen(push0); 	// label : push_0 생성
	labelgen(push1); 	// label : push_1 생성
	labelgen(out); 		// label : out 생성
	fprintf(fp, "-\n"); // a - b

	switch (token) {
		case GT:// a > b일 때 1로
			fprintf(fp, "GOPLUS %s\n", push1);
			fprintf(fp, "GOTO %s\n", push0);
			break;
		case LT:// a < b일 때 1로
			fprintf(fp, "GOMINUS %s\n", push1);
			fprintf(fp, "GOTO %s\n", push0);
			break;
		case LE:// a <= b일 때 1로
			fprintf(fp, "GOPLUS %s\n", push0);
			fprintf(fp, "GOTO %s\n", push1);
			break;
		case GE:// a >= b일 때 1로
			fprintf(fp, "GOMINUS %s\n", push0);
			fprintf(fp, "GOTO %s\n", push1);
			break;
		case EQ:// a == b일 때 1로
			fprintf(fp, "GOTRUE %s\n", push0);
			fprintf(fp, "GOTO %s\n", push1);
			break;
		case NE:// a != b일 때 1로
			fprintf(fp, "GOFALSE %s\n", push0);
			fprintf(fp, "GOTO %s\n", push0);
			break;
	}
	
	// label push_1
	fprintf(fp, "LABEL %s\n", push1);
	fprintf(fp, "PUSH 1\n");
	fprintf(fp, "GOTO %s\n", out);
	
	// label push_0
	fprintf(fp, "LABEL %s\n", push0);
	fprintf(fp, "PUSH 0\n");

	// label out:
	fprintf(fp, "LABEL %s\n", out);
}

void prtcode(int token, int val)
{
	switch (token) {
	case ID:
		if(current_func == NULL) {
			fprintf(fp,"RVALUE %s\n", symtbl[val]);
		} else {
			int local_sym = function_local_sym(val);
			fprintf(fp,"RVALUE %s\n", symtbl[local_sym]);
		}
		break;
	case ID2:
		if(current_func == NULL) {
			fprintf(fp,"LVALUE %s\n", symtbl[val]);
		} else {
			int local_sym = function_local_sym(val);
			fprintf(fp,"LVALUE %s\n", symtbl[local_sym]);
		}
		break;
	case NUM:
		if(val >= 0) 
			fprintf(fp, "PUSH %d\n", val);
		else {
			fprintf(fp, "PUSH 0\n", val);
			fprintf(fp, "PUSH %d\n", -val);
			fprintf(fp, "-\n");
		}
		break;
	case ADD:
		fprintf(fp, "+\n");
		break;
	case SUB:
		fprintf(fp, "-\n");
		break;
	case MUL:
		fprintf(fp, "*\n");
		break;
	case DIV:
		fprintf(fp, "/\n");
		break;
	case ASSGN:
		fprintf(fp, ":=\n");
		break;
	case GETCHAR:
		fprintf(fp, "INCH\n");
		break;
	case GETINT:
		fprintf(fp, "INNUM\n");
		break;
	case PUTCHAR:
		fprintf(fp, "OUTCH %s\n",symtbl[val]);
		break;
	case PUTINT:
		fprintf(fp, "OUTNUM %s\n",symtbl[val]);
		break;
	case EQ:
	case NE:
	case GT:
	case LT:
	case GE:
	case LE:
		prtcmp(token, val);
		break;
	case STMTLIST:
	default:
		break;
	};
}


/*
int gentemp()
{
char buffer[MAXTSYMLEN];
char tempsym[MAXSYMLEN]="TTCBU";

	tsymbolcnt++;
	if (tsymbolcnt > MAXTSYMBOL) printf("temp symbol overflow\n");
	itoa(tsymbolcnt, buffer, 10);
	strcat(tempsym, buffer);
	return( insertsym(tempsym) ); // Warning: duplicated symbol is not checked for lazy implementation
}
*/
void dwgen()
{
int i;
	fprintf(fp, "$ -- END OF EXECUTION CODE AND START OF VAR DEFINITIONS --\n");

// Warning: this code should be different if variable declaration is supported in the language 
	for(i=0; i<maxsym; i++) 
		fprintf(fp, "DW %s\n", symtbl[i]);
	
	func_dwgen();
	fprintf(fp, "END\n");
}

// 각 함수 테이블의 local variable DW
void func_dwgen() {
	/*
	for(int i=0; i<func_cnt; i++) {
		FUNC_INFO* func = func_tbl[i];
		fprintf(fp, "$ -- START OF FUNCTION %s LOCAL VAR DW --\n", func->name);

		printf("함수 %s의 지역변수 개수 %d\n", func->name, func->local_maxsym);
		for(int j=0; j<(func->local_maxsym); j++) {
			fprintf(fp, "$ DW FUNC%s%s\n", func->name,func->local_symtbl[j]);
		}
		fprintf(fp, "$ -- END OF FUNCTION %s LOCAL VAR DW --\n", func->name);
	}
	*/
	fprintf(fp, "DW FUNCret\n");
}
