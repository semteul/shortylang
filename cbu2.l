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

// array�� �̸��� array ��带 ������ ����ü
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

// �Լ� ����

// �Լ� ���̺�
typedef struct func_info {
	char name[MAXSYMLEN];
	char local_symtbl[MAXSYM][MAXSYMLEN];
	char label[LABELSIZE]; // ȣ����ġ (�Լ��� ����)
	char return_label[LABELSIZE]; // ���͹� �� ��ġ
	int return_cnt;
	char return_tbl[MAXSYM][MAXSYMLEN]; // ������ġ
	int local_maxsym;
	Node* stmt_list; // �Լ��� ������ ���� ����Ʈ
} FUNC_INFO;

extern FUNC_INFO* func_tbl[100];
extern int func_cnt;

// �������� ���̺��� �߰�
extern int AddLocalSym(FUNC_INFO* func, char* sym);

// �Լ� ���̺����� �Լ� ã��
extern FUNC_INFO* FindFuncInfo(char* name);

// �Լ� ���̺��� �߰�
extern FUNC_INFO* AddFuncInfo(char* name);

// �Լ� ����ü ����
extern FUNC_INFO* MakeFuncInfo(char* name);

// �Լ� ���� ��ġ �߰� �� �����ڵ� ��ȯ
extern int AddReturn(FUNC_INFO* func, char* label);

// Call ���̺�
typedef struct call_info {
	FUNC_INFO* func; // Call�ϴ� �Լ�
	char return_label[LABELSIZE]; // ������ġ
	int return_code; // �����ڵ�
} CALL_INFO;

extern CALL_INFO* call_tbl[100];
extern int call_cnt;

// Call ���̺��� �߰�
extern CALL_INFO* AddCallInfo(FUNC_INFO* func);

// �̽������� ���ڸ� ���� �̽����̺� ASCII�� ��ȯ
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
����	{ return(IFSTART); }
�̸�	{ return(IFEND); }
�Ǵ�	{ return(ELSEIFSTART); }
�ƴϸ�	{ return(ELSE); }
���	{ return(WHILESTART); }
"�� ����" { return(WHILEEND); }
"�� �ݺ�" { return(REPEAT); }
Ż��	{ return(BREAK); }
"("		{ return(LPAREN);}
")"		{ return(RPAREN); }
"{"		{ return(LBRACE); }
"}"		{ return(RBRACE); }
"["		{ return(LBRACKET); }
"]"		{ return(RBRACKET); }
","		{ return(COMMA); }
"�����Է�(" { return(GETCHAR); }
"�����Է�("	{ return(GETINT); }
"�������(" { return(PUTCHAR); }
"�������("	{ return(PUTINT); }
"���ڿ����(" {return(PUTSTRING); }
"�Լ� "{id}"("(")"|{id}")"|{id}(,{id})*")"); {
	// �Լ� ����
	// �Լ� �̸� (�Ķ����1, �Ķ����2, ...) ���ֺм�
	// �Լ� ���� ���ֺм� �� �Լ� ���̺��� �߰�
	char name[20];
	sscanf(yytext, "�Լ� %[^'(](", name);
	FUNC_INFO* func = AddFuncInfo(name);
	int func_index = func_cnt-1; // �Լ� ���̺� �ε��� ����

	// ������ ����
	char param_str[30];
	int b = sscanf(yytext, "%*[^'(](%[^)]);", param_str); // ��ȣ �� ���ڿ� ����
	if(b != 0) { // �Ķ���Ͱ� �ִ� ���
		// �޸����� ����
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
"�Լ� "{id}"("(")"|{id}")"|{id}(,{id})*")") {
	// �Լ� ���ǹ�
	char name[20];
	sscanf(yytext, "�Լ� %[^'(]", name);

	int i;
	for(i=0; i<func_cnt; i++) {
		if(strcmp(func_tbl[i]->name, name) == 0) {
			break;
		}
	}
	if(i == func_cnt) {
		printf("%s �Լ��� ������� �ʾҽ��ϴ�.\n", name);
		yyerror("�Լ� ���� ����");
		return 0;
	}

	Node* node = MakeNode(FUNC, 0);
	node->tokenval = i; // �Լ� ���̺� �ε���
	yylval = node;
	return FUNCSTART;
}
{id}"(" {
	// �Լ��� (�Ķ����1, �Ķ����2, ...) ���ֺм�
	char name[20];
	sscanf(yytext, "%[^'(]", name);
	// printf("�Լ� %s ȣ��\n", name);

	FUNC_INFO* func = FindFuncInfo(name);
	if(func == NULL){
		printf("%s �Լ��� ������� �ʾҽ��ϴ�.\n", name);
		yyerror("�Լ� ���� ����");
		return 0;
	}

	// call ���̺��� �߰�
	CALL_INFO* call = AddCallInfo(func); 
	int info_index = call_cnt-1; // call ���̺� �ε��� ���� 

	// func�� ������ġ �߰�
	call->return_code = AddReturn(func, call->return_label);

	// call ��� ����
	yylval = MakeNode(CALL, info_index);
	return CALLSTART;
}
"��ȯ"	{ return(RETURN); }
{char}	{  
	if(yytext[1]=='\\') // �̽������� ���� ó��
		temp = to_escape(yytext[2]);
	else
		temp = yytext[1];
	yylval=MakeNode(NUM, temp); 
	return(NUM); }
{string}	{ 
	// printf("string : %s\n", yytext);
	// ���ڿ��� �� ���ں��� ���� ��ū���� ��ȯ
	int i;
	Node* node = MakeNode(STRING, 0);

	// ����ǥ ó�� ���� 1���� ����
	for(i=1;yytext[i] != '\"';i++){
		// printf("string[%d] : %c\n", i, yytext[i]);
		if(yytext[i] == '\\') { // �̽������� ���� ó��
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
	MakeListTree(node, MakeNode(NUM, '\0')); // ������ null ���� ����
	node->tokenval = i+1; // STRING ��忡�� ���ڿ��� ���� ����

	yylval = node;
	return(STRING); 
}
;		{ return(STMTEND); }
����	{ return(START); }
��		{ return(END); }
{id}\[ {
	// �迭 ���ҿ� �����ϴ� ���
	char name[20];
	int size;
	sscanf(yytext, "%[^[]", name);
	size = findArraySize(name);
	if(size == 0){
		printf("%s �� ����������� �迭�Դϴ�.\n", name);
		return(0);
	}
	yylval = MakeArrayNode(name, size);
	return(ARRAY);
}
"�迭 "{id}\[{digit}+\];	{
	// �迭 ������ ���ֺм��Ͽ� �迭 array��� ����
	char name[20];
    int size;

    // �������� �迭 ũ�� ����
    sscanf(yytext, "�迭 %[^[][%d]", name, &size);
	//printf("�迭 %s[%d]\n", name, size);
	
	AddArrayInfo(name, size);
}
"�迭 "{id} {
	// �迭�� �̸� ���ٽ� ArrayNode ����
	char name[20];
	int size;
	sscanf(yytext, "�迭 %s", name);
	size = findArraySize(name);
	if(size == 0){
		printf("%s �� ����������� �迭�Դϴ�.\n", name);
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

// ���ο� Array Node�� ����� + �� �迭 ���Ҹ� symboltbl�� �߰�
// �Ʒ��� ���� ������ ��带 ����
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
		t = insertsym(stringtemp); // symbol_tbl�� �迭 ���� �߰�
		cell = MakeNode(ID,t);

		if(root->son == NULL) // cell�� �ڽĳ�帣 �߰�
			root->son = cell;
		else 
			MakeListTree(root,cell); // cell�� �ڽĳ���� �������� �߰�
	}
	
	return root;
}

yywrap() {}