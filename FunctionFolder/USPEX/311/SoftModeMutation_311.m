function SoftModeMutation_311(Ind_No)

global POOL_STRUC
global POP_STRUC
global ORG_STRUC
global OFF_STRUC

goodMutant = 0;
goodParent=0;

%%%%%%%%%% here we only choose reasonable structure to do mutation
count = 1;
while ~goodParent 
  count = count+1;
  %toMutate = find(ORG_STRUC.tournament>RandInt(1,1,[0,max(ORG_STRUC.tournament)-1]));
  %ind = toMutate(end);
  
  ind = chooseGoodComposition(ORG_STRUC.tournament, POOL_STRUC.POPULATION);
  if count> 10000 | ind<0
       USPEXmessage(516,'',0);
       Random_311(Ind_No);
       break;
  end
  if (sum(POOL_STRUC.POPULATION(ind).numMols)>3)
     goodParent=1;
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
molecules = POOL_STRUC.POPULATION(ind).MOLECULES;
MtypeLIST = POOL_STRUC.POPULATION(ind).MtypeLIST;
numMols   = POOL_STRUC.POPULATION(ind).numMols;
lattice   = POOL_STRUC.POPULATION(ind).LATTICE;
numIons   = POOL_STRUC.POPULATION(ind).numIons;
typesAList= POOL_STRUC.POPULATION(ind).typesAList;
numBlocks = POOL_STRUC.POPULATION(ind).numBlocks;
order     = POOL_STRUC.POPULATION(ind).order;
N = sum(numIons);
vol = det(lattice);

flag=0;

for j = 1 : length(POP_STRUC.SOFTMODEParents)
    numMols1 = POP_STRUC.SOFTMODEParents(j).numIons;
   if  sameComposition(c1,c2)
       continue
   else
       vol1 = det(POP_STRUC.SOFTMODEParents(j).lattice);
       vol_diff = abs(vol-vol1)/vol;
       order1 = POP_STRUC.SOFTMODEParents(j).order;
       order_diff = abs(mean(order)-mean(order1));
       if (vol_diff < 0.02) & (order_diff<0.05)
            flag = 1;
            ID = j;
            break;
        end
    end
end
%%%%%%%%%%%If the chosen struc has been used to do mutation, move to the next soft mode

[freq, eigvector] = calcSoftModes_molecules(ORG_STRUC.NvalElectrons, ORG_STRUC.valences, ind, POOL_STRUC);
freq = diag(freq);
[freq, IX] = sort(freq);
non_zero=0;
if flag==1
   M2 = sum(eigvector(:,IX(POP_STRUC.SOFTMODEParents(j).Softmode_num)).^2);
   M4 = sum(eigvector(:,IX(POP_STRUC.SOFTMODEParents(j).Softmode_num)).^4);
   participation_ratio = M2/M4; % for more details see, f.e., S.Elliott book
   last_good = POP_STRUC.SOFTMODEParents(j).Softmode_Fre;
   for i = 1:length(freq)
       M2 = sum(eigvector(:,IX(i)).^2);
       M4 = sum(eigvector(:,IX(i)).^4);
       pr1 = M2/M4;
      if (freq(i) > (1.05)*last_good) | ((freq(i) >= last_good) & (abs(1-participation_ratio/pr1) > 0.05))
          non_zero = i;
	  break
      end
   end		    
else
   for i = 1:length(freq)        % first non zero element, should usually be 4       
       if freq(i) > 0.0000001
          non_zero = i;
          break;
       end
   end
end

if non_zero==0  %(the structure can not produce softmutation any more)
   current_freq = non_zero;
   good_freq = non_zero;
   loop=0;
   for f = good_freq : non_zero + round((3*N-non_zero)/2)  % about middle of the freq spectra if we ignore the degeneracy
       if loop==1
          break
       else
          for index = 1 : N
              vec(1) = eigvector((index-1)*3+1,IX(f));
              vec(2) = eigvector((index-1)*3+2,IX(f));
              vec(3) = eigvector((index-1)*3+3,IX(f));
              vecnorm(index) = norm(vec);
          end
          normfac = max(vecnorm(1:N))/ORG_STRUC.howManyMut;                     
          for i = 0 : 10
              if rand<0.5
                 [MUT_mol, deviation] = move_along_SoftMode_molMutation(molecules, (1-i/21)*eigvector(:,IX(f))/normfac, MtypeLIST);
              else
                 [MUT_mol, deviation] = move_along_SoftMode_molMutation(molecules, (i/21-1)*eigvector(:,IX(f))/normfac, MtypeLIST);
              end
              goodMutant = newMolCheck(MUT_mol, lattice, MtypeLIST,ORG_STRUC.minDistMatrice-0.1);
              if goodMutant == 1
                 loop=1;  
                 break;
             end
         end
      end  %if loop==1
      good_freq=good_freq+1;
   end  %% Outer loop, freq++ 

   if goodMutant == 1
      info_parents = struct('parent', {},'mut_degree', {},'mut_mode',{},'mut_fre',{}, 'enthalpy', {});
      info_parents(1).parent = num2str(POOL_STRUC.POPULATION(ind).Number);
      info_parents.mut_degree = deviation;
      info_parents.mut_mode=f;
      info_parents.mut_fre=freq(f);
      info_parents.enthalpy = POOL_STRUC.POPULATION(ind).enthalpy/sum(numIons);
      OFF_STRUC.POPULATION(Ind_No).Parents = info_parents;
      OFF_STRUC.POPULATION(Ind_No).MOLECULES = MUT_mol;
      OFF_STRUC.POPULATION(Ind_No).LATTICE = lattice;
      OFF_STRUC.POPULATION(Ind_No).numIons = numIons;
      OFF_STRUC.POPULATION(Ind_No).numBlocks=numBlocks;
      OFF_STRUC.POPULATION(Ind_No).numMols = numMols;
      OFF_STRUC.POPULATION(Ind_No).MtypeLIST = MtypeLIST;
      OFF_STRUC.POPULATION(Ind_No).typesAList = typesAList;
      OFF_STRUC.POPULATION(Ind_No).howCome = 'softmutate';

      disp(['Structure ' num2str(Ind_No) '  generated by softmutation']);
      if flag == 1
         POP_STRUC.SOFTMODEParents(ID).Softmode_Fre=freq(f);
         POP_STRUC.SOFTMODEParents(ID).Softmode_num=f;
      else
         POP_STRUC.SOFTMODEParents(end+1).lattice=lattice;
         POP_STRUC.SOFTMODEParents(end).molecules=molecules;
         POP_STRUC.SOFTMODEParents(end).fingerprint=FINGERPRINT;
         POP_STRUC.SOFTMODEParents(end).Softmode_Fre=freq(f);
         POP_STRUC.SOFTMODEParents(end).Softmode_num=f;
         POP_STRUC.SOFTMODEParents(end).numIons=numIons;
         POP_STRUC.SOFTMODEParents(end).numMols=numMols;
         POP_STRUC.SOFTMODEParents(end).order=order;
      end        % Loop: cosine_dist
   else
        disp([' --> Switch Structure ' num2str(Ind_No) '  generated by mutation']);
        Mutation_311(Ind_No);
    end
else
   disp([' --> Switch Structure ' num2str(Ind_No) '  generated by mutation']);
    Mutation_311(Ind_No);
end

