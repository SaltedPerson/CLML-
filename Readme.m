
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
warning off %#ok<WNOFF>
clear all
clc
addpath(genpath('.'));
starttime = datestr(now,0); 

load 'data/genbase.mat';

%% Optimization Parameters
optmParameter.alpha   = 2^-6;  % 2.^[-10:10] % label correlation
optmParameter.beta    = 2^-7; % 2.^[-10:10] % label specific feature 
optmParameter.gamma   = 2^3; % {0.1, 1, 10} % initialization for W
optmParameter.lamda   = 2^-7;% instance correlation
optmParameter.lamda2   = 2^-5;% common features

optmParameter.maxIter           = 30;%����������
optmParameter.minimumLossMargin = 0.001;%���ε�������С��ʧ���  0.0001
optmParameter.bQuiet             = 1;

%% Model Parameters
modelparameter.cv_num             = 5;
modelparameter.L2Norm             = 1; % {0,1}
modelparameter.tuneThreshold      = 1;
%% cross validation
if exist('train_data','var')==1
    data=[train_data;test_data];
    target=[train_target,test_target];    
    clear train_data test_data train_target test_target
end
if exist('dataset','var')==1
    data = dataset;
    target = class ;
    clear dataset class
end
data     = double(data);
target = double(target>0);
num_data = size(data,1);
if modelparameter.L2Norm == 1
    temp_data = data;
    temp_data = temp_data./repmat(sqrt(sum(temp_data.^2,2)),1,size(temp_data,2));
    if sum(sum(isnan(temp_data)))>0
        temp_data = data+eps;
        temp_data = temp_data./repmat(sqrt(sum(temp_data.^2,2)),1,size(temp_data,2));
    end
else
    temp_data = data;
end 

clear data;

randorder = randperm(num_data);
Result_CLML  = zeros(15,modelparameter.cv_num);

for j = 1:modelparameter.cv_num
    fprintf('CLML Running Fold - %d/%d \n',j,modelparameter.cv_num); 
   %% the training and test parts are generated by fixed spliting with the given random order
    [cv_train_data,cv_train_target,cv_test_data,cv_test_target ] = NewgenerateCVSet( temp_data,target',randorder,j,modelparameter.cv_num );
    cv_train_target=cv_train_target';
    cv_test_target=cv_test_target';
   %% Training 
    [W]  = CLML( cv_train_data, cv_train_target',optmParameter);%����ά�Ⱦ�����
    Outputs       = (cv_test_data*W)';%Yhat = X * W ,�õ�ʵ�ʵ���ֵ��������ͨ����ֵ��ȷ������ֵ

   %% TuneThreshold 
   if modelparameter.tuneThreshold == 1
     fscore                 = (cv_train_data*W)';
     [ tau,  currentResult] = TuneThreshold( fscore, cv_train_target, 1, 2);%������Ϊת��
     Pre_Labels             = Predict(Outputs,tau);%����Ϊת��
   else 
     Pre_Labels  = round(Outputs);%��������
     Pre_Labels  = (Pre_Labels >= 1);%����������Ϊ1����֮Ϊ0
     Pre_Labels  = double(Pre_Labels);
   end
   %% Evaluation of CLML
    Result_CLML(:,j) = EvaluationAll(Pre_Labels,Outputs,cv_test_target);%������Ϊת��
end

%% the average results 
Avg_Result = zeros(15,2);
Avg_Result(:,1)=mean(Result_CLML,2);%ƽ��ֵ 2������ 
Avg_Result(:,2)=std(Result_CLML,1,2);%��׼��
fprintf('\nResults of CLML\n');
PrintResults(Avg_Result);
endtime = datestr(now,0);



