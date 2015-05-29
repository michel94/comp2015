@_false = global i1 0
@_true = global i1 1
@_a = global i32 0
@_d = global i1 0
@_r = global double 0.000000e+00
@argc_ = global i32 0
@argv_ = global i8** null
define i32 @setr(double* dereferenceable(8) %_r) {
%_setr = alloca i32
%1 = alloca double*
store double* %_r, double** %1
%2 = add i32 5, 0
%3 = sitofp i32 %2 to double
store double %3, double* %_r
%4 = add i32 1, 0
store i32 %4, i32* %_setr
%5 = load double* %_r
%6 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([6 x i8]* @.str_2, i32 0, i32 0), double %5)
%7 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([2 x i8]* @.str_0, i32 0, i32 0))
%8 = load i32* %_setr
ret i32 %8
}
define i32 @abs(i32 %a){
	%1 = icmp slt i32 %a, 0
	br i1 %1, label %la, label %lb
	la:
		%2 = sub i32 0, %a
		ret i32 %2
	lb:
		ret i32 %a
}
define i32 @main(i32 %argc, i8** %argv) {
%1 = alloca i32
%2 = alloca i8**
store i32 %argc, i32* %1
store i8** %argv, i8*** %2
%3 = load i32* %1
store i32 %3, i32* @argc_
%4 = load i8*** %2
store i8** %4, i8*** @argv_

%5 = load i1* @_false
%6 = load i1* @_false
%7 = or i1 %5, %6
%8 = load i1* @_false
%9 = load i1* @_true
%10 = icmp  ule i1 %8, %9
%11 = add i1 %10, 1
%12 = or i1 %7, %11
%13 = load i1* @_true
%14 = load i1* @_false
%15 = icmp ne i1 %13, %14
%16 = load i1* @_false
%17 = load i1* @_true
%18 = icmp  ult i1 %16, %17
%19 = and i1 %15, %18
%20 = or i1 %12, %19
store i1 %20, i1* @_d
%21 = load i1* @_false
%22 = load i1* @_false
%23 = or i1 %21, %22
%24 = load i1* @_false
%25 = or i1 %23, %24
%26 = load i1* @_false
%27 = load i1* @_true
%28 = and i1 %26, %27
%29 = or i1 %25, %28
%30 = load i1* @_true
%31 = or i1 %29, %30
store i1 %31, i1* @_d
%32 = add i32 3, 0
%33 = sub i32 0, %32
store i32 %33, i32* @_a
%34 = load i32* @_a
%35 = load double* @_r
%36 = sitofp i32 %34 to double
%37 = fcmp  ogt double %36, %35
%38 = load i1* @_d
%39 = add i1 %38, 1
%40 = or i1 %37, %39
store i1 %40, i1* @_d
%41 = load i1* @_d
store i1 %41, i1* @_d
%42 = add i32 3, 0
%43 = add i32 2, 0
%44 = urem i32 %42, %43
%45 = call i32 @abs(i32 %44)
%46 = sub i32 0, %45
store i32 %46, i32* @_a
%47 = load i1* @_d
call void @print_boolean(i1 %47)
%48 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([2 x i8]* @.str_7, i32 0, i32 0))
%49 = load i32* @_a
%50 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([3 x i8]* @.str_3, i32 0, i32 0), i32 %44)
%51 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([2 x i8]* @.str_0, i32 0, i32 0))
ret i32 0
}
@.str_0 = private unnamed_addr constant [2 x i8] c"\0A\00"
@.str_1 = private unnamed_addr constant [2 x i8] c" \00"
@.str_2 = private unnamed_addr constant [6 x i8] c"%.12E\00"
@.str_3 = private unnamed_addr constant [3 x i8] c"%d\00"
@.str_4 = private unnamed_addr constant [3 x i8] c"%s\00"
@.str_5 = private unnamed_addr constant [5 x i8] c"TRUE\00"
@.str_6 = private unnamed_addr constant [6 x i8] c"FALSE\00"
@.str_7 = private unnamed_addr constant [2 x i8] c" \00"

declare i32 @atoi(i8*)
declare i32 @printf(i8*, ...)
define i32 @valparam(i32 %pos){
%1 = alloca i32
store i32 %pos, i32* %1
%2 = load i32* %1
%3 = sext i32 %2 to i64
%4 = load i8*** @argv_
%5 = getelementptr inbounds i8** %4, i64 %3
%6 = load i8** %5
%7 = call i32 @atoi(i8* %6)
ret i32 %7
}
define void @print_boolean(i1 %_b){
br i1 %_b, label %if_bool, label %else_bool
if_bool:
 call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([5 x i8]* @.str_5, i32 0, i32 0))
 br label %end_bool
else_bool:
 call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([6 x i8]* @.str_6, i32 0, i32 0))
 br label %end_bool
end_bool: ret void
}
define i32 @paramcount(){
 %1 = load i32* @argc_
 %2 = sub i32 %1, 1
ret i32 %2
}
