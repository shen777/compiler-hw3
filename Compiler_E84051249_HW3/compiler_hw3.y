/*	Definition section */
%{
    #include "common.h" //Extern variables that communicate with lex
    #include <stdio.h>
    // #define YYDEBUG 1
    // int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    /* Symbol table function - you can add new function if needed. */
    static void create_symbol();
    static void insert_symbol(char* iden,int ScopeLevel,int type, int array,int lineno);
    static int lookup_symbol(char* iden,int ScopeLevel);
    static void dump_symbol(int ScopeLevel);

    char *intrger="int32";
    char *floatnum="float32";
    char *stringptr="string";
    char *boolen="bool";
    static char* printcharptr(int type)
    {
        if(type==1)
        {
            return intrger;
        }
        else if(type==2)
        {
            return floatnum;
        }
        else if(type==3)
        {
            return stringptr;
        }
        return boolen;
    }

    

    int symbolTableIndex[50];
    char* symbolTableName[50];
   
    int symbolTableType[50];// 1=int32 2=float32 3=string 4=bool 5=array
    int symbolTableAddress[50];
    int symbolTableLineno[50];
    int symbolTableElementType[50];//0=not array 1=int32 2=float32 3=string 4=bool
    int symbolTableScopeLevel[50];

    int currentScopeLevel=0;
    int currentAddress=0;
    int currentIndex=0;

    int arrayFlag=0;
    int currenttype;
    int printtype=0; //0=not array 1=int32 2=float32 3=string 4=bool
    int KeepTypeFlag=0;
    int conversion=0;
    int preType=0;
    int preIsLiteral=0;
    int isLiteral=0;
    int noPrintError=0;
    int loadStoreFlag=0;//0 store(left) 1 load(right)
    int currentVariableIndex=0;
    int assignVariableIndex=0;
    int branchVariable=0;
    int declareflag=0;
    int isarray=0;
    int conversionIorF=0;//0=I 1=F
    int ifElseVariableExit=0;
    int ifElseVariableElse=0;
    int forVariable=0;
    int forVariableExit=0;
    int has_error=0;
    int in_array=0;
    int in_for_loop_nested=0;
    FILE *fp;
%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    int b_val;
    /* ... */
}

/* Token without return */
%token VAR
%token INT FLOAT BOOL STRING
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token ELSE FOR EQL GEQ IF LAND LEQ LOR NEQ PRINT PRINTLN NEWLINE INC DEC TRUE FALSE

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT
%token <b_val> BOOL_LIT
%token <s_val> ID

/* Nonterminal with return, which need to sepcify type */
// %type <type> Type TypeName ArrayType

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    :{ create_symbol();
        fp=fopen("hw3.j","w");
        fputs(".source hw3.j\n",fp);
        fputs(".class public Main\n",fp);
        fputs(".super java/lang/Object\n",fp);
        fputs(".method public static main([Ljava/lang/String;)V\n",fp);
        fputs(".limit stack 1000\n",fp);
        fputs(".limit locals 1000\n",fp);}
        Stmt Stmts {
            fputs("return\n",fp);
            fputs(".end method\n",fp);
            fclose(fp);
            if(has_error==1)
            {
                remove("hw3.j");
            }
        }
;

Stmts
    : Stmt Stmts
    | {dump_symbol(currentScopeLevel); }
;

Stmt
    : declarestmt NEWLINE {isLiteral=0;}
    | blockstmt  NEWLINE {isLiteral=0;}
    | ifstmt NEWLINE {isLiteral=0;}
    | forstmt NEWLINE {isLiteral=0;}
    | printstmt NEWLINE {isLiteral=0;}
    | assignmentstmt NEWLINE {isLiteral=0;}
    | expression NEWLINE {isLiteral=0;}
    | indecstmt NEWLINE {isLiteral=0;}
    | NEWLINE  {isLiteral=0;}
;


indecstmt
    : ID INC{
        if(KeepTypeFlag==0){printtype=symbolTableElementType[lookup_symbol($1,currentScopeLevel)];}
        if(lookup_symbol($1,currentScopeLevel)==-1){printf("error\n");}
        else{printf("IDENT (name=%s, address=%d)\n",$1,symbolTableAddress[lookup_symbol($1,currentScopeLevel)]);}
        if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==1)
        {
            fputs("ldc 1\n",fp);
            char str[80];
            sprintf(str,"iload %d\n",lookup_symbol($1,currentScopeLevel));
            fputs(str,fp);
            fputs("iadd\n",fp);
            char str1[80];
            sprintf(str1,"istore %d\n",lookup_symbol($1,currentScopeLevel));
            fputs(str1,fp);
        }
        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==2)
        {
            fputs("ldc 1.0\n",fp);
            char str[80];
            sprintf(str,"fload %d\n",lookup_symbol($1,currentScopeLevel));
            fputs(str,fp);
            fputs("fadd\n",fp);
            char str1[80];
            sprintf(str1,"fstore %d\n",lookup_symbol($1,currentScopeLevel));
            fputs(str1,fp);
        }
        printf("INC\n");
        }
    | ID DEC { if(KeepTypeFlag==0){
        printtype=symbolTableElementType[lookup_symbol($1,currentScopeLevel)];}
        if(lookup_symbol($1,currentScopeLevel)==-1){printf("error\n");}
        else{printf("IDENT (name=%s, address=%d)\n",$1,symbolTableAddress[lookup_symbol($1,currentScopeLevel)]);}
        if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==1)
        {
            char str[80];
            sprintf(str,"iload %d\n",lookup_symbol($1,currentScopeLevel));
            fputs(str,fp);
            fputs("ldc 1\n",fp);
            fputs("isub\n",fp);
            char str1[80];
            sprintf(str1,"istore %d\n",lookup_symbol($1,currentScopeLevel));
            fputs(str1,fp);
        }
        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==2)
        {
            char str[80];
            sprintf(str,"fload %d\n",lookup_symbol($1,currentScopeLevel));
            fputs(str,fp);
            fputs("ldc 1.0\n",fp);
            fputs("fsub\n",fp);
            char str1[80];
            sprintf(str1,"fstore %d\n",lookup_symbol($1,currentScopeLevel));
            fputs(str1,fp);
        }
        printf("DEC\n");
        }
;

declarestmt
    :   VAR  ID  DCLTYPE EXTENBDASSIGNMENT {insert_symbol($2,currentScopeLevel,currenttype,arrayFlag,yylineno);arrayFlag=0;
        if(symbolTableType[lookup_symbol($2,currentScopeLevel)]==5)
        {
            //array
        if(symbolTableElementType[lookup_symbol($2,currentScopeLevel)]==1)
        {
            fputs("newarray int\n",fp);
            char str[80];
            sprintf(str,"astore %d\n",lookup_symbol($2,currentScopeLevel));
            fputs(str,fp);
            
        }
        else if(symbolTableElementType[lookup_symbol($2,currentScopeLevel)]==2)
        {
            fputs("newarray float\n",fp);
            char str[80];
            sprintf(str,"astore %d\n",lookup_symbol($2,currentScopeLevel));
            fputs(str,fp);
        }
        else
        {
           printf("declare error 1\n");
        }
        }
        else
        {
        if(symbolTableElementType[lookup_symbol($2,currentScopeLevel)]==1)
        {
            char str[80];
            sprintf(str,"istore %d\n",lookup_symbol($2,currentScopeLevel));
            fputs(str,fp);
        }
        else if(symbolTableElementType[lookup_symbol($2,currentScopeLevel)]==2)
        {
            char str[80];
            sprintf(str,"fstore %d\n",lookup_symbol($2,currentScopeLevel));
            fputs(str,fp);
        }
        else if(symbolTableElementType[lookup_symbol($2,currentScopeLevel)]==3)
        {
            char str[80];
            sprintf(str,"astore %d\n",lookup_symbol($2,currentScopeLevel));
            fputs(str,fp);
        }
        else if(symbolTableElementType[lookup_symbol($2,currentScopeLevel)]==4)
        {
            char str[80];
            sprintf(str,"istore %d\n",lookup_symbol($2,currentScopeLevel));
            fputs(str,fp);
        }
        else
        {
           printf("declare error 2\n");
        }
        }
        }
;

DCLTYPE
    : INT   {currenttype=1;}
    | FLOAT {currenttype=2;}
    | STRING   {currenttype=3;}
    | BOOL  {currenttype=4;}
    | '['  INT_LIT {
            isarray=1;
            printf("INT_LIT %d\n",$2);
            char str[80];
            sprintf(str,"ldc %d\n",$2);
            fputs(str,fp);
            } ']' DCLTYPE {arrayFlag=1;}
;

EXTENBDASSIGNMENT
    : '=' ID {
        if(KeepTypeFlag==0){
            printtype=symbolTableElementType[lookup_symbol($2,currentScopeLevel)];
        }

        if(lookup_symbol($2,currentScopeLevel)==-1)
            {printf("error\n");
        }
        else{
            printf("IDENT (name=%s, address=%d)\n",$2,symbolTableAddress[lookup_symbol($2,currentScopeLevel)]);
            
        }

        if(symbolTableElementType[lookup_symbol($2,currentScopeLevel)]==1)
        {
            char str[80];
            sprintf(str,"iload %d\n",lookup_symbol($2,currentScopeLevel));
            fputs(str,fp);
        }
        else if(symbolTableElementType[lookup_symbol($2,currentScopeLevel)]==2)
        {
            char str[80];
            sprintf(str,"fload %d\n",lookup_symbol($2,currentScopeLevel));
            fputs(str,fp);
        }
        else if(symbolTableElementType[lookup_symbol($2,currentScopeLevel)]==3)
        {
            char str[80];
            sprintf(str,"aload %d\n",lookup_symbol($2,currentScopeLevel));
            fputs(str,fp);
        }
        else if(symbolTableElementType[lookup_symbol($2,currentScopeLevel)]==4)
        {
            char str[80];
            sprintf(str,"iload %d\n",lookup_symbol($2,currentScopeLevel));
            fputs(str,fp);
        }
        else
        {
            printf("array\n");
        }}
    | '=' {loadStoreFlag=1;} expression
    |{ if(isarray==0){
        if(currenttype==1)
        {
            fputs("ldc 0\n",fp);
        }
        else if(currenttype==2)
        {
            fputs("ldc 0.0\n",fp);
        }
        else if(currenttype==3)
        {
            fputs("ldc \"\"\n",fp);
        }
        else if(currenttype==4)
        {
            fputs("iconst_1\n",fp);
        }
        else
        {
            printf("array\n");
        }
     }
     else
     {
         isarray=0;
     }
    }
;

assignmentstmt
    : ID '=' {loadStoreFlag=1;}expression {
                        printf("assign\n");
                        
                        if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==1)
                        {
                            char str[80];
                            sprintf(str,"istore %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==2)
                        {
                            char str[80];
                            sprintf(str,"fstore %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==3)
                        {
                            char str[80];
                            sprintf(str,"astore %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==4)
                        {
                            char str[80];
                            sprintf(str,"istore %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }                      
            }
    | ID {
            char str[80];
            sprintf(str,"aload %d\n",lookup_symbol($1,currentScopeLevel));
            fputs(str,fp);
        }'[' expression ']' {loadStoreFlag=1;}'=' expression{ 
                        if(symbolTableType[lookup_symbol($1,currentScopeLevel)]!=5)
                        {
                            printf("assign array error\n");
                        }
                        else
                        {   if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==1){fputs("iastore\n",fp);}
                            else{fputs("fastore\n",fp);}
                        }
                        }
    | assign_var ADD_ASSIGN expression {printf("ADD_ASSIGN\n");if(printtype==1)
                {
                    fputs("iadd\n",fp);
                    char str1[80];
                    sprintf(str1,"istore %d\n",assignVariableIndex);
                    fputs(str1,fp);
                }
                else if(printtype==2)
                {
                    fputs("fadd\n",fp);
                    char str1[80];
                    sprintf(str1,"fstore %d\n",assignVariableIndex);
                    fputs(str1,fp);
                }
                else
                {
                    printf("add assign error\n");
                }}
    | assign_var SUB_ASSIGN expression {printf("SUB_ASSIGN\n");if(printtype==1)
                {
                    fputs("isub\n",fp);
                    char str1[80];
                    sprintf(str1,"istore %d\n",assignVariableIndex);
                    fputs(str1,fp);
                }
                else if(printtype==2)
                {
                    fputs("fsub\n",fp);
                    char str1[80];
                    sprintf(str1,"fstore %d\n",assignVariableIndex);
                    fputs(str1,fp);
                }
                else
                {
                    printf("sub assign error\n");
                } }
    | assign_var MUL_ASSIGN expression {printf("MUL_ASSIGN\n");if(printtype==1)
                {
                    fputs("imul\n",fp);
                    char str1[80];
                    sprintf(str1,"istore %d\n",assignVariableIndex);
                    fputs(str1,fp);
                }
                else if(printtype==2)
                {
                    fputs("fmul\n",fp);
                    char str1[80];
                    sprintf(str1,"fstore %d\n",assignVariableIndex);
                    fputs(str1,fp);
                }
                else
                {
                    printf("mul assign error\n");
                }}
    | assign_var QUO_ASSIGN expression {printf("QUO_ASSIGN\n");if(printtype==1)
                {
                    fputs("idiv\n",fp);
                    char str1[80];
                    sprintf(str1,"istore %d\n",assignVariableIndex);
                    fputs(str1,fp);
                }
                else if(printtype==2)
                {
                    fputs("fdiv\n",fp);
                    char str1[80];
                    sprintf(str1,"fstore %d\n",assignVariableIndex);
                    fputs(str1,fp);
                }
                else
                {
                    printf("quo assign error\n");
                } }
    | assign_var REM_ASSIGN expression {printf("REM_ASSIGN\n");if(printtype==1)
                {
                    fputs("irem\n",fp);
                    char str1[80];
                    sprintf(str1,"istore %d\n",assignVariableIndex);
                    fputs(str1,fp);
                }
                else
                {
                    printf("IREM assign error\n");
                }  }
    | INT_LIT ADD_ASSIGN expression {
        printf("error:%d: invalid operation: (can not assign int lit)\n",yylineno);
        has_error=1;
    }
;

assign_var
    : ID {  int flag1=0;
            if(KeepTypeFlag==0){ 
            assignVariableIndex=flag1=lookup_symbol($1,currentScopeLevel);
            noPrintError=flag1;
            printtype=symbolTableElementType[flag1];
            }

                        if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==1)
                        {
                            char str[80];
                            sprintf(str,"iload %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==2)
                        {
                            char str[80];
                            sprintf(str,"fload %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==3)
                        {
                            char str[80];
                            sprintf(str,"aload %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==4)
                        {
                            char str[80];
                            sprintf(str,"iload %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }}
;


expression
    :  expression {preType=printtype;}  LOR llpexpression  {
        if(printtype!=4||preType!=4)
        {
            printf("error:%d: invalid operation: (operator LOR not defined on int32)\n",yylineno);
            has_error=1;
        }
        printf("LOR\n");if(KeepTypeFlag==0){printtype=4;}
        fputs("ior\n",fp);}
    | llpexpression
    | '"' STRING_LIT '"' {printf("STRING_LIT %s\n",$2);
            printtype=3;
            char str[80];
            sprintf(str,"ldc \"%s\"\n",$2);
            fputs(str,fp);
        }
;

hpexpression
    : hpexpression {preType=printtype;} '*' hpexpression  {
        if((printtype!=preType)&&(conversion==0)){
            printf("error:%d: invalid operation: MUL (mismatched types %s and %s)\n",yylineno,printcharptr(preType),printcharptr(printtype));
            has_error=1;
            }
        printf("MUL\n");
        if(printtype==1)
        {
            fputs("imul\n",fp);
        }
        else if(printtype==2)
        {
            fputs("fmul\n",fp);
        }
        else
        {
            printf("mul error \n");
        }
        }
    | hpexpression '/' hpexpression  {printf("QUO\n");
                if(printtype==1)
                {
                    fputs("idiv\n",fp);
                }
                else if(printtype==2)
                {
                    fputs("fdiv\n",fp);
                }
                else
                {
                    printf("div error \n");
                }
            }
    | hpexpression {preType=printtype;}  '%' hpexpression  {
        if(preType==2||printtype==2)
        {
            printf("error:%d: invalid operation: (operator REM not defined on float32)\n",yylineno);
            has_error=1;
        }
        printf("REM\n");
        fputs("irem\n",fp);
        }
    | unaryExpr
;

mpexpression 
    : mpexpression  {preType=printtype;} '+' hpexpression  {
        if((printtype!=preType)&&(conversion==0)){
            printf("error:%d: invalid operation: ADD (mismatched types %s and %s)\n",yylineno,printcharptr(preType),printcharptr(printtype));
            has_error=1;
            }
        else
        {   if(conversion==1)
            {
                if(conversionIorF==0)
                {
                    fputs("iadd\n",fp);
                }
                else
                {
                    fputs("fadd\n",fp);
                }
            }
            else
            {
                if(printtype==1||in_array==1)
                {
                    fputs("iadd\n",fp);
                }
                else if(printtype==2)
                {
                    fputs("fadd\n",fp);
                }
                else
                {
                    printf("add error1\n");
                }
            }   
                printf("ADD\n");
        }        
               }
    | mpexpression {preType=printtype;} '-' hpexpression  {
        if((printtype!=preType)&&(conversion==0)){
        printf("error:%d: invalid operation: SUB (mismatched types %s and %s)\n",yylineno,printcharptr(preType),printcharptr(printtype));
        has_error=1;
        }
                if(printtype==1||in_array==1)
                {
                    fputs("isub\n",fp);
                }
                else if(printtype==2)
                {
                    fputs("fsub\n",fp);
                }
                else
                {
                    printf("sub error1 \n");
                }
        printf("SUB\n");}
    | hpexpression
;

lpexpression
    : lpexpression EQL mpexpression  {printf("EQL\n");
                if(printtype==1)
                {
                    fputs("isub\n",fp);
                    char str[80];
                    sprintf(str,"ifeq L_cmp_eq_%d\n",branchVariable);
                    fputs(str,fp);
    
                    fputs("iconst_0\n",fp);

                    char str1[80];
                    sprintf(str1,"goto L_cmp_eq_%d\n",branchVariable+1);
                    fputs(str1,fp);
                    
                    char str2[80];
                    sprintf(str2,"L_cmp_eq_%d:\n",branchVariable);
                    fputs(str2,fp);

                    fputs("iconst_1\n",fp);

                    char str3[80];
                    sprintf(str3,"L_cmp_eq_%d:\n",branchVariable+1);
                    fputs(str3,fp);
                    branchVariable=branchVariable+2;
                }
                else if(printtype==2)
                {
                    fputs("fcmpl\n",fp);
                    char str[80];
                    sprintf(str,"ifeq L_cmp_eq_%d\n",branchVariable);
                    fputs(str,fp);
    
                    fputs("iconst_0\n",fp);

                    char str1[80];
                    sprintf(str1,"goto L_cmp_eq_%d\n",branchVariable+1);
                    fputs(str1,fp);
                    
                    char str2[80];
                    sprintf(str2,"L_cmp_eq_%d:\n",branchVariable);
                    fputs(str2,fp);

                    fputs("iconst_1\n",fp);

                    char str3[80];
                    sprintf(str3,"L_cmp_eq_%d:\n",branchVariable+1);
                    fputs(str3,fp);
                    branchVariable=branchVariable+2;
                }
                else
                {
                    printf("EQL error \n");
                }
                if(KeepTypeFlag==0){printtype=4;}
            }
    | lpexpression NEQ mpexpression  {printf("NEQ\n");
                if(printtype==1)
                {
                    fputs("isub\n",fp);
                    char str[80];
                    sprintf(str,"ifeq L_cmp_neq_%d\n",branchVariable);
                    fputs(str,fp);
    
                    fputs("iconst_1\n",fp);

                    char str1[80];
                    sprintf(str1,"goto L_cmp_neq_%d\n",branchVariable+1);
                    fputs(str1,fp);
                    
                    char str2[80];
                    sprintf(str2,"L_cmp_neq_%d:\n",branchVariable);
                    fputs(str2,fp);

                    fputs("iconst_0\n",fp);

                    char str3[80];
                    sprintf(str3,"L_cmp_neq_%d:\n",branchVariable+1);
                    fputs(str3,fp);
                    branchVariable=branchVariable+2;
                }
                else if(printtype==2)
                {
                    fputs("fcmpl\n",fp);
                    char str[80];
                    sprintf(str,"ifeq L_cmp_neq_%d\n",branchVariable);
                    fputs(str,fp);
    
                    fputs("iconst_1\n",fp);

                    char str1[80];
                    sprintf(str1,"goto L_cmp_neq_%d\n",branchVariable+1);
                    fputs(str1,fp);
                    
                    char str2[80];
                    sprintf(str2,"L_cmp_neq_%d:\n",branchVariable);
                    fputs(str2,fp);

                    fputs("iconst_0\n",fp);

                    char str3[80];
                    sprintf(str3,"L_cmp_neq_%d:\n",branchVariable+1);
                    fputs(str3,fp);
                    branchVariable=branchVariable+2;
                }
                else
                {
                    printf("NEQ error \n");
                }
                if(KeepTypeFlag==0){printtype=4;}
            }
    | lpexpression LEQ mpexpression  {printf("LEQ\n");
                if(printtype==1)
                {
                    fputs("isub\n",fp);
                    char str[80];
                    sprintf(str,"ifle L_cmp_leq_%d\n",branchVariable);
                    fputs(str,fp);
    
                    fputs("iconst_0\n",fp);

                    char str1[80];
                    sprintf(str1,"goto L_cmp_leq_%d\n",branchVariable+1);
                    fputs(str1,fp);
                    
                    char str2[80];
                    sprintf(str2,"L_cmp_leq_%d:\n",branchVariable);
                    fputs(str2,fp);

                    fputs("iconst_1\n",fp);

                    char str3[80];
                    sprintf(str3,"L_cmp_leq_%d:\n",branchVariable+1);
                    fputs(str3,fp);
                    branchVariable=branchVariable+2;
                }
                else if(printtype==2)
                {
                    fputs("fcmpl\n",fp);
                    char str[80];
                    sprintf(str,"ifle L_cmp_leq_%d\n",branchVariable);
                    fputs(str,fp);
    
                    fputs("iconst_0\n",fp);

                    char str1[80];
                    sprintf(str1,"goto L_cmp_leq_%d\n",branchVariable+1);
                    fputs(str1,fp);
                    
                    char str2[80];
                    sprintf(str2,"L_cmp_leq_%d:\n",branchVariable);
                    fputs(str2,fp);

                    fputs("iconst_1\n",fp);

                    char str3[80];
                    sprintf(str3,"L_cmp_leq_%d:\n",branchVariable+1);
                    fputs(str3,fp);
                    branchVariable=branchVariable+2;
                }
                else
                {
                    printf("LEQ error \n");
                }
                if(KeepTypeFlag==0){printtype=4;}
            }
    | lpexpression GEQ mpexpression  {printf("GEQ\n");
            if(printtype==1)
                {
                    fputs("isub\n",fp);
                    char str[80];
                    sprintf(str,"ifge L_cmp_geq_%d\n",branchVariable);
                    fputs(str,fp);
    
                    fputs("iconst_0\n",fp);

                    char str1[80];
                    sprintf(str1,"goto L_cmp_geq_%d\n",branchVariable+1);
                    fputs(str1,fp);
                    
                    char str2[80];
                    sprintf(str2,"L_cmp_geq_%d:\n",branchVariable);
                    fputs(str2,fp);

                    fputs("iconst_1\n",fp);

                    char str3[80];
                    sprintf(str3,"L_cmp_geq_%d:\n",branchVariable+1);
                    fputs(str3,fp);
                    branchVariable=branchVariable+2;
                }
                else if(printtype==2)
                {
                    fputs("fcmpl\n",fp);
                    char str[80];
                    sprintf(str,"ifge L_cmp_geq_%d\n",branchVariable);
                    fputs(str,fp);
    
                    fputs("iconst_0\n",fp);

                    char str1[80];
                    sprintf(str1,"goto L_cmp_geq_%d\n",branchVariable+1);
                    fputs(str1,fp);
                    
                    char str2[80];
                    sprintf(str2,"L_cmp_geq_%d:\n",branchVariable);
                    fputs(str2,fp);

                    fputs("iconst_1\n",fp);

                    char str3[80];
                    sprintf(str3,"L_cmp_geq_%d:\n",branchVariable+1);
                    fputs(str3,fp);
                    branchVariable=branchVariable+2;
                }
                else
                {
                    printf("GEQ error \n");
                }
                if(KeepTypeFlag==0){printtype=4;}        
            }
    | lpexpression '<' mpexpression  {printf("LSS\n");
            if(printtype==1)
                {
                    fputs("isub\n",fp);
                    char str[80];
                    sprintf(str,"iflt L_cmp_l_%d\n",branchVariable);
                    fputs(str,fp);
    
                    fputs("iconst_0\n",fp);

                    char str1[80];
                    sprintf(str1,"goto L_cmp_l_%d\n",branchVariable+1);
                    fputs(str1,fp);
                    
                    char str2[80];
                    sprintf(str2,"L_cmp_l_%d:\n",branchVariable);
                    fputs(str2,fp);

                    fputs("iconst_1\n",fp);

                    char str3[80];
                    sprintf(str3,"L_cmp_l_%d:\n",branchVariable+1);
                    fputs(str3,fp);
                    branchVariable=branchVariable+2;
                }
                else if(printtype==2)
                {
                    fputs("fcmpl\n",fp);
                    char str[80];
                    sprintf(str,"iflt L_cmp_l_%d\n",branchVariable);
                    fputs(str,fp);
    
                    fputs("iconst_0\n",fp);

                    char str1[80];
                    sprintf(str1,"goto L_cmp_l_%d\n",branchVariable+1);
                    fputs(str1,fp);
                    
                    char str2[80];
                    sprintf(str2,"L_cmp_l_%d:\n",branchVariable);
                    fputs(str2,fp);

                    fputs("iconst_1\n",fp);

                    char str3[80];
                    sprintf(str3,"L_cmp_l_%d:\n",branchVariable+1);
                    fputs(str3,fp);
                    branchVariable=branchVariable+2;
                }
                else
                {
                    printf("< error \n");
                }
                if(KeepTypeFlag==0){printtype=4;}
            }
    | lpexpression '>' mpexpression  {printf("GTR\n");
            if(printtype==1)
                {
                    fputs("isub\n",fp);
                    char str[80];
                    sprintf(str,"ifgt L_cmp_g_%d\n",branchVariable);
                    fputs(str,fp);
    
                    fputs("iconst_0\n",fp);

                    char str1[80];
                    sprintf(str1,"goto L_cmp_g_%d\n",branchVariable+1);
                    fputs(str1,fp);
                    
                    char str2[80];
                    sprintf(str2,"L_cmp_g_%d:\n",branchVariable);
                    fputs(str2,fp);

                    fputs("iconst_1\n",fp);

                    char str3[80];
                    sprintf(str3,"L_cmp_g_%d:\n",branchVariable+1);
                    fputs(str3,fp);
                    branchVariable=branchVariable+2;
                }
                else if(printtype==2)
                {

                    fputs("fcmpl\n",fp);
                    char str[80];
                    sprintf(str,"ifgt L_cmp_g_%d\n",branchVariable);
                    fputs(str,fp);
    
                    fputs("iconst_0\n",fp);

                    char str1[80];
                    sprintf(str1,"goto L_cmp_g_%d\n",branchVariable+1);
                    fputs(str1,fp);
                    
                    char str2[80];
                    sprintf(str2,"L_cmp_g_%d:\n",branchVariable);
                    fputs(str2,fp);

                    fputs("iconst_1\n",fp);

                    char str3[80];
                    sprintf(str3,"L_cmp_g_%d:\n",branchVariable+1);
                    fputs(str3,fp);
                    branchVariable=branchVariable+2;
                }
                else
                {
                    printf("> error \n");
                }
                if(KeepTypeFlag==0){printtype=4;}   
            }
    | mpexpression
;

llpexpression
    : llpexpression  {preType=printtype;} LAND lpexpression {
        if(printtype!=4||preType!=4)
        {
            printf("error:%d: invalid operation: (operator LAND not defined on int32)\n",yylineno);
            has_error=1;
        }
        printf("LAND\n");if(KeepTypeFlag==0){printtype=4;}
        fputs("iand\n",fp);
        }
    | lpexpression
;


unaryExpr
    : primaryExpr
    | unaryOp unaryExpr
    | '!' unaryExpr {printf("NOT\n");
        fputs("iconst_1\n",fp);
        fputs("ixor\n",fp);
        }
;

unaryOp
    : '+' {printf("ADD\n");
        if(printtype==1)
                {
                    fputs("iadd\n",fp);
                }
                else if(printtype==2)
                {
                    fputs("fadd\n",fp);
                }
                else
                {
                    printf("add error2 \n");
                }
        }
    | '-' {printf("SUB\n");
                if(printtype==1)
                {
                    fputs("isub\n",fp);
                }
                else if(printtype==2)
                {
                    fputs("fsub\n",fp);
                }
                else
                {
                    printf("sub error2 \n");
                }
        }
;

primaryExpr
    : literal
    | ID { int flag1=0;
        
        if(KeepTypeFlag==0){ 
            flag1=lookup_symbol($1,currentScopeLevel);
            noPrintError=flag1;
            printtype=symbolTableElementType[flag1];
            } 
        if(flag1!=-1){assignVariableIndex=flag1;
                    printf("IDENT (name=%s, address=%d)\n",$1,symbolTableAddress[flag1]);
                    if(loadStoreFlag==0)
                    {
                        if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==1)
                        {
                            char str[80];
                            sprintf(str,"istore %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==2)
                        {
                            char str[80];
                            sprintf(str,"fstore %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==3)
                        {
                            char str[80];
                            sprintf(str,"astore %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==4)
                        {
                            char str[80];
                            sprintf(str,"istore %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else
                        {
                            char str[80];
                            sprintf(str,"iastore %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                            printf("array1\n");
                        }
                    }
                    else
                    {
                        if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==1)
                        {
                            char str[80];
                            sprintf(str,"iload %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==2)
                        {
                            char str[80];
                            sprintf(str,"fload %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==3)
                        {
                            char str[80];
                            sprintf(str,"aload %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==4)
                        {
                            char str[80];
                            sprintf(str,"iload %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                        }
                        else
                        {
                            char str[80];
                            sprintf(str,"aload %d\n",lookup_symbol($1,currentScopeLevel));
                            fputs(str,fp);
                            printf("array3\n");
                        }
                    }
                    
                    }
                }
    | '(' expression ')' 
    | ID {  char str[80];
            sprintf(str,"aload %d\n",lookup_symbol($1,currentScopeLevel));
            fputs(str,fp);
            if(KeepTypeFlag==0){ 
            int flag1=lookup_symbol($1,currentScopeLevel);
            noPrintError=flag1;
            printtype=symbolTableElementType[flag1];
            } 
                    }'[' {KeepTypeFlag=1;in_array=1;} expression ']' {KeepTypeFlag=0; in_array=0;
                    if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==1){fputs("iaload\n",fp);}
                    else{fputs("faload\n",fp);}
                    }
    | INT '(' llpexpression ')'   {printf("F to I\n");conversion=1;conversionIorF=0;
            fputs("f2i\n",fp);
            }
    | FLOAT '(' llpexpression ')' {printf("I to F\n");conversion=1;conversionIorF=1;
            fputs("i2f\n",fp);
            }
;


literal
    : signLiteral
    | INT_LIT {printf("INT_LIT %d\n",$1);if(KeepTypeFlag==0){printtype=1;} isLiteral=1;
                char str[80];
                sprintf(str,"ldc %d\n",$1);
                fputs(str,fp);
                }
    | FLOAT_LIT {printf("%s %f\n", "FLOAT_LIT",$1);if(KeepTypeFlag==0){printtype=2;}
                char str[80];
                sprintf(str,"ldc %f\n",$1);
                fputs(str,fp);
                }
    | BOOL_LIT  {printf("%s\n", "BOOL_LIT"); printf($1?"true":"false");if(KeepTypeFlag==0){printtype=4;}
                char str[80];
                sprintf(str,"ldc %d\n",$1);
                fputs(str,fp);
                }
    | '"' STRING_LIT '"'  {printf("STRING_LIT %s\n",$2); if(KeepTypeFlag==0){printtype=3;}
                char str[80];
                sprintf(str,"ldc \"%s\"\n",$2);
                fputs(str,fp);
                }
    | TRUE {printf("TRUE\n");if(KeepTypeFlag==0){printtype=4;}
            fputs("iconst_1\n",fp);
            }
    | FALSE {printf("FALSE\n");if(KeepTypeFlag==0){printtype=4;}
            fputs("iconst_0\n",fp);
            }
;

signLiteral
    : '+' INT_LIT {printf("INT_LIT %d\nPOS\n",$2);char str[80];
                sprintf(str,"ldc %d\n",$2);
                fputs(str,fp);}
    | '-' INT_LIT {printf("INT_LIT %d\nNEG\n",$2);char str[80];
                sprintf(str,"ldc %d\n",$2);
                fputs(str,fp);
                fputs("ineg\n",fp);}
    | '+' FLOAT_LIT {printf("FLOAT_LIT %f\nPOS\n",$2);char str[80];
                sprintf(str,"ldc %f\n",$2);
                fputs(str,fp);}
    | '-' FLOAT_LIT {printf("FLOAT_LIT %f\nNEG\n",$2);char str[80];
                sprintf(str,"ldc %f\n",$2);
                fputs(str,fp);
                fputs("fneg\n",fp);}
;


blockstmt
    : '{' NEWLINE {currentScopeLevel++;} Stmts '}' { 
            currentScopeLevel--;}
;
ifBlockstmt
    : '{' NEWLINE {currentScopeLevel++;} Stmts '}' { 
            currentScopeLevel--;
            char str[80];
            sprintf(str,"goto L_if_exit_%d\n",ifElseVariableElse);
            fputs(str,fp);}
;

forBlockstmt
    : '{' NEWLINE {currentScopeLevel++;} Stmts '}' { 
            currentScopeLevel--;
            }
;

ifstmt
    : IF condition {
            if(printtype!=4)
            {
                printf("error:%d: non-bool (type %s) used as for condition\n",yylineno+1,printcharptr(printtype));
                has_error=1;
            }
            char str[80];
            sprintf(str,"ifeq L_if_false_%d\n",ifElseVariableElse);
            fputs(str,fp);
        } ifBlockstmt {
            char str[80];
            sprintf(str,"ifeq L_if_exit_%d\n",ifElseVariableExit);
            fputs(str,fp);
        } elsestmt {
            char str[80];
            sprintf(str,"L_if_exit_%d:\n",ifElseVariableExit);
            fputs(str,fp);
            ifElseVariableExit+=2;
        }
;

condition
    : expression
;

elsestmt
    : ELSE {char str[80];
            sprintf(str,"L_if_false_%d:\n",ifElseVariableElse);
            fputs(str,fp);
            ifElseVariableElse+=2;
            } ifstmt
    | ELSE {char str[80];
            sprintf(str,"L_if_false_%d:\n",ifElseVariableElse);
            fputs(str,fp);
            ifElseVariableElse+=2;
            } blockstmt
    | {char str[80];
            sprintf(str,"L_if_false_%d:\n",ifElseVariableElse);
            fputs(str,fp);
            ifElseVariableElse+=2;
            } 
;

forstmt
    : FOR { if(in_for_loop_nested==0){
            char str[80];
            sprintf(str,"L_for_begin_%d:\n",forVariable);
            fputs(str,fp);
            in_for_loop_nested=1;}
            } forMidstmt {in_for_loop_nested=0;}
;


forMidstmt
    : condition {if(printtype!=4){printf("error:%d: non-bool (type %s) used as for condition\n",yylineno+1,printcharptr(printtype));has_error=1;}
            char str[80];
            sprintf(str,"ifeq L_for_exit_%d\n",forVariable);
            fputs(str,fp);
            } forBlockstmt {
            char str[80];
            sprintf(str,"goto L_for_begin_%d\n",forVariable);
            fputs(str,fp);
            char str1[80];
            sprintf(str1,"L_for_exit_%d:\n",forVariable);
            fputs(str1,fp);
            forVariable++;
            //  !!!!!
            }
    | initstmt { 
            if(in_for_loop_nested==1)
            {
                forVariable++;
                char str[80];
                sprintf(str,"L_for_begin_%d:\n",forVariable);
                fputs(str,fp); 
            }
            }  ';' condition {
            if(printtype!=4)
            {printf("error:%d: non-bool (type %s) used as for condition\n",yylineno+1,printcharptr(printtype));has_error=1;}
            char str[80];
            sprintf(str,"ifeq L_for_exit_%d\n",forVariableExit);
            fputs(str,fp);
            }
            ';' ID INC {
                if(in_for_loop_nested==1)
                {
                    forVariable++;
                }
            }
            forBlockstmt
            {
            if(in_for_loop_nested==1)
                {
                    forVariable--;
                }
            char str2[80];
            sprintf(str2,"iload %d\n",lookup_symbol($7,currentScopeLevel));
            fputs(str2,fp);
            fputs("ldc 1\n",fp);
            fputs("iadd\n",fp);
            char str3[80];
            sprintf(str3,"istore %d\n",lookup_symbol($7,currentScopeLevel));
            fputs(str3,fp);

            char str[80];
            sprintf(str,"goto L_for_begin_%d\n",forVariable);
            fputs(str,fp);
            if(in_for_loop_nested==1)
            {
                forVariable--;
                in_for_loop_nested=0;
            }
            char str1[80];
            sprintf(str1,"L_for_exit_%d:\n",forVariableExit);
            fputs(str1,fp);
            forVariableExit++;
            if(in_for_loop_nested==1)
            {
                forVariable--;
            }
            //  !!!!!
            }
;

initstmt
    : ID '=' INT_LIT {
        printf("ASSIGN\n");
            char str[80];
            sprintf(str,"ldc %d\n",$3);
            fputs(str,fp);
            if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==1)
            {
                char str[80];
                sprintf(str,"istore %d\n",lookup_symbol($1,currentScopeLevel));
                fputs(str,fp);
            }
            else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==2)
            {
                char str[80];
                sprintf(str,"fstore %d\n",lookup_symbol($1,currentScopeLevel));
                fputs(str,fp);
            }
            else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==3)
            {
                char str[80];
                sprintf(str,"astore %d\n",lookup_symbol($1,currentScopeLevel));
                fputs(str,fp);
            }
            else if(symbolTableElementType[lookup_symbol($1,currentScopeLevel)]==4)
            {
                char str[80];
                sprintf(str,"istore %d\n",lookup_symbol($1,currentScopeLevel));
                fputs(str,fp);
            }
                
                }
;

printstmt
    : PRINT {loadStoreFlag=1;} expression  {
        if(printtype==1)
        {
            printf("PRINT int32\n");
            fputs("getstatic java/lang/System/out Ljava/io/PrintStream;\n",fp);
            fputs("swap\n",fp);
            fputs("invokevirtual java/io/PrintStream/print(I)V\n",fp);
        }
        else if(printtype==2)
        {
            printf("PRINT float32\n");
            fputs("getstatic java/lang/System/out Ljava/io/PrintStream;\n",fp);
            fputs("swap\n",fp);
            fputs("invokevirtual java/io/PrintStream/print(F)V\n",fp);
        }
        else if(printtype==3)
        {
            printf("PRINT string\n");
            fputs("getstatic java/lang/System/out Ljava/io/PrintStream;\n",fp);
            fputs("swap\n",fp);
            fputs("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n",fp);
        }
        else if(printtype==4)
        {
            printf("PRINT bool\n");
            char str[80];
            sprintf(str,"ifne L_cmp_%d\n",branchVariable);
            fputs(str,fp);
            fputs("ldc \"false\"\n",fp);
            char str1[80];
            sprintf(str1,"goto L_cmp_%d\n",branchVariable+1);
            fputs(str1,fp);
            char str2[80];
            sprintf(str2,"L_cmp_%d:\n",branchVariable);
            fputs(str2,fp);
            fputs("ldc \"true\"\n",fp);
            char str3[80];
            sprintf(str3,"L_cmp_%d:\n",branchVariable+1);
            fputs(str3,fp);
            fputs("getstatic java/lang/System/out Ljava/io/PrintStream;\n",fp);
            fputs("swap\n",fp);
            fputs("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n",fp);
            branchVariable+=2;
        }
        else
        {
             printf("PRINT error\n");
        }
    }
    | PRINTLN {loadStoreFlag=1;} expression  {
        if(printtype==1)
        {
            printf("PRINTLN int32\n");
            fputs("getstatic java/lang/System/out Ljava/io/PrintStream;\n",fp);
            fputs("swap\n",fp);
            fputs("invokevirtual java/io/PrintStream/println(I)V\n",fp);
        }
        else if(printtype==2)
        {
            printf("PRINTLN float32\n");
            fputs("getstatic java/lang/System/out Ljava/io/PrintStream;\n",fp);
            fputs("swap\n",fp);
            fputs("invokevirtual java/io/PrintStream/println(F)V\n",fp);
        }
        else if(printtype==3)
        {
            printf("PRINTLN string\n");
            fputs("getstatic java/lang/System/out Ljava/io/PrintStream;\n",fp);
            fputs("swap\n",fp);
            fputs("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n",fp);
        }
        else if(printtype==4)
        {
            printf("PRINTLN bool\n");
            char str[80];
            sprintf(str,"ifne L_cmp_%d\n",branchVariable);
            fputs(str,fp);
            fputs("ldc \"false\"\n",fp);
            char str1[80];
            sprintf(str1,"goto L_cmp_%d\n",branchVariable+1);
            fputs(str1,fp);
            char str2[80];
            sprintf(str2,"L_cmp_%d:\n",branchVariable);
            fputs(str2,fp);
            fputs("ldc \"true\"\n",fp);
            char str3[80];
            sprintf(str3,"L_cmp_%d:\n",branchVariable+1);
            fputs(str3,fp);
            fputs("getstatic java/lang/System/out Ljava/io/PrintStream;\n",fp);
            fputs("swap\n",fp);
            fputs("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n",fp);
            branchVariable+=2;
        }
        else
        {
             printf("PRINTLN error\n");
        }
    }
;

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    yylineno = 0;
    yyparse();

	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    return 0;
}

static void create_symbol() {
   return;
}

static void insert_symbol(char* iden,int ScopeLevel,int type, int array,int lineno) {
    //printf("currentIndex=%d\n",currentIndex);
    //printf("currentSCOPELEVEL=%d\n",ScopeLevel);
    for(int i=0;i<currentIndex;i++)
    {
        if(strcmp(iden,symbolTableName[i])==0 && ScopeLevel==symbolTableScopeLevel[i])
        {
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n",yylineno,iden,symbolTableLineno[i]);
            has_error=1;
            return;
        }
    }
    currentVariableIndex=currentIndex;
    symbolTableScopeLevel[currentIndex]=ScopeLevel;
    symbolTableName[currentIndex]=iden;
    symbolTableAddress[currentIndex]=currentAddress;
    currentAddress++;
    
    symbolTableIndex[currentIndex]=currentIndex;
    symbolTableLineno[currentIndex]=lineno;

    if(array==1)
    {
        //is array
        symbolTableType[currentIndex]=5;
        symbolTableElementType[currentIndex]=type;
    }
    else
    {
        symbolTableElementType[currentIndex]=type;
        symbolTableType[currentIndex]=type;
    }
    printf("> Insert {%s} into symbol table (scope level: %d)\n", symbolTableName[currentIndex], ScopeLevel);
    /*
    printf("> Insert symbol table (scope level: %d)\n", ScopeLevel);
    printf("%-10s%-10s%-10s%-10s%-10s%s\n",
           "Index", "Name", "Type", "Address", "Lineno", "Element type");
    printf("%-10d%-10s%-10d%-10d%-10d%d\n",
                    currentIndex, symbolTableName[currentIndex],symbolTableType[currentIndex], symbolTableAddress[currentIndex], symbolTableLineno[currentIndex], symbolTableElementType[currentIndex]);
    */
    currentIndex++;
    return;
}

static int lookup_symbol(char* iden,int ScopeLevel) {
    //printf("currentIndex=%d\n",currentIndex);
    for(int i=currentIndex-1;i>=0;i--)
    {
        if(strcmp(iden,symbolTableName[i])==0)
        {
            return i;
        }
    }
    printf("error:%d: undefined: %s\n",yylineno+1,iden);
    has_error=1;
    return -1;
}

static void dump_symbol(int ScopeLevel) {
    //printf("currentIndex=%d\n",currentIndex);
    //printf("currentSCOPELEVEL=%d\n",ScopeLevel);
    //printf("currentScopeLevel=%d    currentIndex=%d\n",ScopeLevel,currentIndex);
    printf("> Dump symbol table (scope level: %d)\n", ScopeLevel);
    printf("%-10s%-10s%-10s%-10s%-10s%s\n",
           "Index", "Name", "Type", "Address", "Lineno", "Element type");
    int flag=0;
    int newIndex=currentIndex;
    int printindex=-1;
    for(int i=0;i<currentIndex;i++)
    {
        if(symbolTableScopeLevel[i]==ScopeLevel)
        {
            printindex++;
            //printf("dump\n");
            if(flag==0)
            {
                flag=1;
                newIndex=i;
            }
            if(symbolTableType[i]==5)
            {
                //array
                if(symbolTableElementType[i]==1)
                {
                    //int32
                    printf("%-10d%-10s%-10s%-10d%-10d%s\n",
                    printindex, symbolTableName[i], "array", symbolTableAddress[i], symbolTableLineno[i], "int32");
                }
                else if(symbolTableElementType[i]==2)
                {
                    //float32
                     printf("%-10d%-10s%-10s%-10d%-10d%s\n",
                    printindex, symbolTableName[i], "array", symbolTableAddress[i], symbolTableLineno[i], "float32");
                }
                else if(symbolTableElementType[i]==3)
                {
                    //string
                     printf("%-10d%-10s%-10s%-10d%-10d%s\n",
                    printindex, symbolTableName[i], "array", symbolTableAddress[i], symbolTableLineno[i], "string");
                }
                else if(symbolTableElementType[i]==4)
                {
                    //bool
                     printf("%-10d%-10s%-10s%-10d%-10d%s\n",
                    printindex, symbolTableName[i], "array", symbolTableAddress[i], symbolTableLineno[i], "bool");
                }
                else
                {
                    printf("error!!!!!\n");
                }
            }
            else
            {
                if(symbolTableType[i]==1)
                {
                    //int32
                     printf("%-10d%-10s%-10s%-10d%-10d%s\n",
                    printindex, symbolTableName[i], "int32", symbolTableAddress[i], symbolTableLineno[i], "-");
                }
                else if(symbolTableType[i]==2)
                {
                    //float32
                     printf("%-10d%-10s%-10s%-10d%-10d%s\n",
                    printindex, symbolTableName[i], "float32", symbolTableAddress[i], symbolTableLineno[i], "-");
                }
                else if(symbolTableType[i]==3)
                {
                    //string
                     printf("%-10d%-10s%-10s%-10d%-10d%s\n",
                    printindex, symbolTableName[i], "string", symbolTableAddress[i], symbolTableLineno[i], "-");
                }
                else if(symbolTableType[i]==4)
                {
                    //bool
                     printf("%-10d%-10s%-10s%-10d%-10d%s\n",
                    printindex, symbolTableName[i], "bool", symbolTableAddress[i], symbolTableLineno[i], "-");
                }
                else
                {
                    printf("error!!!!!!\n");
                }
            }
             
        }
    }
   currentIndex=newIndex;
   //printf("currentIndex=%d\n",currentIndex);
}
