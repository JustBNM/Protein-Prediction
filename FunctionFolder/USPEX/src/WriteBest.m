function WriteBest(resFolder, energyUnits)
%Output the BESTINDIVIDUALS info
%Last updated by MR (2014/04/10)

global ORG_STRUC
global USPEX_STRUC

if nargin == 2 && strcmp(energyUnits, 'kcal/mol')
    energyUnits = '(kcal/mol)';
else
    energyUnits     = '   (eV)   ';
end

fpath = [ resFolder '/BESTIndividuals'];
fp = fopen(fpath, 'w');
fprintf(fp,  'Gen   ID    Origin   Composition    Enthalpy      RMSD      Fitness   Q_entr A_order S_order\n');
fprintf(fp, ['                                   ' energyUnits '      nm\n']);

for i = 1:length(USPEX_STRUC.GENERATION)
    for j=1:length(USPEX_STRUC.GENERATION(i).BestID)
        IND     = USPEX_STRUC.GENERATION(i).BestID(j);
        if IND > 0
           gen     = USPEX_STRUC.POPULATION(IND).gen;
           fit     = USPEX_STRUC.POPULATION(IND).Fitness;
           enth    = USPEX_STRUC.POPULATION(IND).Enthalpies(end);
           num     = USPEX_STRUC.POPULATION(IND).numIons;
           entropy = USPEX_STRUC.POPULATION(IND).struc_entr;
           howcome = USPEX_STRUC.POPULATION(IND).howCome;
           order   = USPEX_STRUC.POPULATION(IND).order;
             s     = USPEX_STRUC.POPULATION(IND).S_order;
           order  = USPEX_STRUC.POPULATION(IND).order;
           rmsd     = USPEX_STRUC.POPULATION(IND).RMSD;
           if ORG_STRUC.spin == 1 
               magmom   = sum(USPEX_STRUC.POPULATION(IND).magmom_ions(end,2:end));
               magType  = USPEX_STRUC.POPULATION(IND).magmom_ions(end,1);       
           else
               magmom =[];
               magType=[];
           end
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           % Process 'N/A' case:
           comp_format = '[%11s]';
           if strcmp(num, 'N/A')
               composition = num;
               comp_format = '%-13s';
           end

           entropy_format = '%6.3f';
           if strcmp(entropy, 'N/A')
               entropy_format = '%-6s';
           end

           ao_format = '%6.3f';
           if strcmp(order, 'N/A')
               ao_format = '%-7s';
           end

           s_format = '%6.3f';
           if strcmp(s, 'N/A')
               s_format = '%-6s';
           end
    
           mag_format = '%8.3f';
           if strcmp(magmom, 'N/A')
               mag_format = '%-6s';
           end

           magType_format = '%6s';
           if strcmp(magmom, 'N/A')
              magType_format = '%-6s';
           end

           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


           if ~strcmp(num, 'N/A')
               composition = sprintf('%3d',num);
               shift=[4, 2, 1]; %so far we only consider 6 component
               if size(composition,2)<11
                  composition=[composition,blanks(shift(length(num)))];
               end
           end

           if isempty(entropy)
              entropy = 0;
           end

           if strcmp(order, 'N/A')
               a_o = order;
           else
               if sum(num)>0
                  a_o = sum(order)/sum(num);
               else
                  a_o = 0;
               end
           end

       fprintf(fp,['%3d %4d %-11s '  comp_format ' %9.3f ' ' %9.3f  '  ' %10.3f '  ' ' entropy_format ' ' ao_format ' ' s_format '\n'], ...
                    gen,IND,howcome, composition,  enth,     rmsd,         fit,           entropy,           a_o,          s);
       end
    end
end
fclose(fp);
