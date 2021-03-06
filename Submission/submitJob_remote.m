function jobNumber = submitJob_remote(USPEX, Index, Ind_No)

global POP_STRUC
global ORG_STRUC

%-------------------------------------------------------------
%This routine is to check if the submitted job is done or not
%2   : whichCluster (default 0, 1: local submission; 2: remote submission)
%C-20GPa : remoteFolder
%-------------------------------------------------------------

%-------------------------------------------------------------
if false
%Step1: To prepare the job script, runvasp.sh
  fp = fopen('myrun', 'w');
  fprintf(fp, '#!/bin/bash\n');
  fprintf(fp, '#SBATCH -N 1\n');
  fprintf(fp, '#SBATCH -n 1\n');
  fprintf(fp, '#SBATCH -p RT\n');
  fprintf(fp, '#SBATCH --job-name=1shf\n');
  fprintf(fp, '#SBATCH -o out -e err\n');
  fprintf(fp, '#SBATCH --comment="calculate protein ishf"\n');
  fclose(fp);
%------------------------------------------------------------------------------------------------------------
%Step 2: Copy the files to the remote machine

%Step2-1: Specify the PATH to put your calculation folder
Home = ['/home/AI/shipilov.ab/statistic_collection/1cei']; %'pwd' of your home directory of your remote machine
Address = 'shipilov.ab@calc.cod.phystech.edu'; %your target server: username@address
Path = [Home '/' USPEX '/CalcFold' num2str(Index)];  %Just keep it

%------------------------------------------------------------------------------------------------------------
%Step 3: to submit the job and get JobID, i.e. the exact command to submit job.

%Здесь твой код, который ты хочешь запустить в каждом CalcFold в формате: 
[nothing, nothing] = unix(['cat /dev/null > myrun']);
[nothing, nothing] = unix(['echo "#!/bin/sh"  >> myrun']);
[nothing, nothing] = unix(['echo "#SBATCH -o out"  >> myrun']);
[nothing, nothing] = unix(['echo "#SBATCH -p RT"  >> myrun']);
[nothing, nothing] = unix(['echo "#SBATCH -J U-' num2str(POP_STRUC.generation),'I',num2str(Ind_No),'S',num2str(POP_STRUC.POPULATION(Ind_No).Step),'"  >> myrun']);
[nothing, nothing] = unix(['echo "#SBATCH -t 06:00:00"  >> myrun']);
[nothing, nothing] = unix(['echo "#SBATCH -N 1"  >> myrun']);
[nothing, nothing] = unix(['echo "#SBATCH -n 1"  >> myrun']);
[nothing, nothing] = unix(['echo "#SBATCH --comment=\"1cei protein calculation\""  >> myrun']);
[nothing, nothing] = unix(['echo cd ' Path ' >> myrun']);
%[nothing, nothing] = unix(['echo "mpirun vasp_std> log" >> myrun']);
[a,b]=unix(['echo "~/tools/miniconda3/envs/env/bin/python ' Path '/random_protein.py input 1 pseudo memory > output"  >> myrun']);

%Создаем папку USPEX в директории Home, а в ней папки CalcFold
try
[a,b]=unix(['ssh ' Address ' "cd ' Home '; mkdir ' USPEX '"' ]);  
catch
end

try
[a,b]=unix(['ssh ' Address ' "cd ' Home '; cd ' USPEX '; mkdir ' Path '"' ]);
catch
end

%Копируем все необходимые файлы из папки на рюрике в папку на миптовском кластере, в которой будет исполняться код
[nothing, nothing] = unix(['scp -r * ' Address ':' Path]);

[a,v]=unix(['ssh ' Address ' "cd ' Path '; sbatch myrun"']);
start_marker=findstr(v,'job ');
jobNumber = v(start_marker(1)+4:end-1);
disp([ 'Individual : ' num2str(Ind_No) ' -- JobID :', num2str(jobNumber) ]);


end

if true
%-----------------------------------------------------------------------
%Step2-1: Specify the PATH to put your calculation folder
Home = ['/home/AI/shipilov.ab/statistic_collection']; %'pwd' of your home directory of your remote machine
Address = 'shipilov.ab@calc.cod.phystech.edu'; %your target server: username@address
Path = [Home '/' USPEX '/CalcFold' num2str(Index)];  %Just keep it

%Создаем папку USPEX в директории Home, а в ней папки CalcFold
try
[a,b]=unix(['ssh ' Address ' "cd ' Home '; mkdir ' USPEX '"' ]);
catch
end

try
[a,b]=unix(['ssh ' Address ' "cd ' Home '; cd ' USPEX '; mkdir ' Path '"' ]);
catch
end

%Находим свободные ноды для сабмита
[nothing, node] = unix(['~/miniconda3/bin/python ../Submission/remote_free_nodes.py']);

%Step 3: to submit the job and get JobID, i.e. the exact command to submit job.

%Здесь твой код, который ты хочешь запустить в каждом CalcFold в формате: 
fp = fopen('myrun', 'w');
fprintf(fp,'ssh %s "cd %s; ./final_run"', node, Path);
fclose(fp);
[nothing, nothing] = unix(['chmod +x myrun']);

fp = fopen('final_run', 'w');
fprintf(fp,'#!/bin/sh\n');
fprintf(fp,'nohup ~/tools/miniconda3/envs/env/bin/python random_protein.py input 1 pseudo memory > output 2>&1 | echo $! > script_id &');
fclose(fp);
[nothing, nothing] = unix(['chmod +x final_run']);

%создаём check_status
[nothing, nothing] = unix(['echo ssh ' node ' "ps aux | grep shipilov.ab > jobinfo.dat"  > check_status']);
[nothing, nothing] = unix(['chmod +x check_status']);

%Копируем все необходимые файлы из папки на рюрике в папку на миптовском кластере, в которой будет исполняться код
[nothing, nothing] = unix(['scp -r * ' Address ':' Path]);

[nothing,nothing]=unix(['ssh ' Address ' "cd ' Path '; ./myrun"']);
[nothing, nothing] = unix(['scp ' Address ':' Path '/script_id script_id.log']);
while ~exist('script_id.log', 'file')
    [nothing, nothing] = unix(['scp ' Address ':' Path '/script_id script_id.log']);
end
jobNumber=dlmread('script_id.log');
%[nothing,jobNumber]=unix(['ssh ' Address ' "cd ' Path '; cat script_id"'])
disp([ 'Individual : ' num2str(Ind_No) ' -- JobID :', num2str(jobNumber) ]);
end
