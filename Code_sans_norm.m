clear all
%% on charge le bon environnement
% Se mettre sous hpc1 et verifier que le bon environnement a
% deja ete loader: matlab/R2019a SPM/12 fsl/5.0.11 python/3.6.5
% freesurfer/6.0.1 ashs/2017_09 (ou ashs/2.0.0_07202018 si atlas princeton)

% se mettre dans le repertoire de travail des pretraitements ==> chemin de
% sortie
WORKINGPATH = '/homes_unix/quinton/Documents/PEPsy/derivatives/';
cd(WORKINGPATH);

% Liste des sujets 
liste_sujets_pepsy  = textread('/homes_unix/quinton/Documents/list_subject_pepsy.txt', '%s');
nsubj = numel(liste_sujets_pepsy);

% numero de session (a remplacer selon la session a traiter)
numsession = 1;

%% chemins necessaires a l ensemble des pretraitements
for i=1%:nsubj correspondant à la ligne dans le fichier texte
   
    fprintf('Sujets: %s\n ',liste_sujets_pepsy{i});
    
% chemin pour recuperer les images d interets dans le dataset fmap
chemin_dataset_fmap = (sprintf('/homes_unix/quinton/Documents/PEPsy/dataset/%s/ses-0%d/fmap',liste_sujets_pepsy{i},numsession));

% chemin pour recuperer les images d interets dans le dataset anat
chemin_dataset_anat = (sprintf('/homes_unix/quinton/Documents/PEPsy/dataset/%s/ses-0%d/anat',liste_sujets_pepsy{i},numsession));
    
% chemin pour recuperer les images d interets dans le dataset dwi
chemin_dataset_dwi = (sprintf('/homes_unix/quinton/Documents/PEPsy/dataset/%s/ses-0%d/dwi',liste_sujets_pepsy{i},numsession));

% chemin deriratives des pretaitements DTI du sujet 
chemin_derivatives_DTI = (sprintf('%s%s/ses-0%d/DTI',WORKINGPATH,liste_sujets_pepsy{i},numsession));

% chemin deriratives des pretaitements SPM12 du sujet
chemin_derivatives_SPM12 = (sprintf('%s%s/ses-0%d/SPM12',WORKINGPATH,liste_sujets_pepsy{i},numsession));

% chemin deriratives des pretaitements DTI_MNI_SPM12 du sujet
chemin_derivatives_DTI_MNI_SPM12 = (sprintf('%s%s/ses-0%d/SPM12',WORKINGPATH,liste_sujets_pepsy{i},numsession));
end

%% pretraitements DTI FSL 5.11 

cd(WORKINGPATH);

for i=1%1:nsubj
    fprintf('Sujets: %s\n pretraitement DTI',liste_sujets_pepsy{i});
    
    if exist(pathname,'%s')
        
     
        % creation des repertoires de travail et on se met dans le repertoire
    unix(sprintf('mkdir %s', liste_sujets_pepsy{i}));
    cd(liste_sujets_pepsy{i});
    
   
    
    unix(sprintf('mkdir ses-0%d', numsession));
    cd(sprintf('ses-0%d', numsession));
    
    unix('mkdir DTI');
    cd('DTI');
    
    

    % chemin des pretaitements DTI du sujet
    chemin_derivatives_DTI = (sprintf('%s%s/ses-0%d/DTI',WORKINGPATH,liste_sujets_pepsy{i},numsession));
    % chemin pour recuperer les images d interets (AP et PA) dans le dataset fmap
    chemin_dataset_fmap = (sprintf('/homes_unix/quinton/Documents/PEPsy/dataset/%s/ses-0%d/fmap',liste_sujets_pepsy{i},numsession));
    
    %% etape 1 = TOPUP FSL = corrections des distorsions EPI induites par les differences de susceptibilites magnetiques presentent le long de la direction de la phase d encodage (ant vers post)
    
    % on cree un fichier 4D des images AP (ant vers post = phase negative = blip_up) + PA (post vers ant = phase positive = blip_down), lesquelles contiennent une image nodif (volume 2) + une image ponderee en diff (volume 1 = 1 direction), lesquelles permettent que les regions frontales ecrasees en AP soient allongees en PA et inversement
    % -t = concatene dans le temps
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ;fslmerge -t %s_ses-0%d_all_AP_PA.nii %s/%s_ses-0%d_dir-AP_epi.nii.gz %s/%s_ses-0%d_dir-PA_epi.nii.gz',liste_sujets_pepsy{i},numsession, chemin_dataset_fmap, liste_sujets_pepsy{i},numsession, chemin_dataset_fmap, liste_sujets_pepsy{i},numsession));
    
    % on extrait les images nodifs des AP et PA qui seront utilises ulterieurement
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; fslroi %s/%s_ses-0%d_all_AP_PA.nii %s_ses-0%d_nodif_AP.nii 1 1', chemin_derivatives_DTI, liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession));
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; fslroi %s/%s_ses-0%d_all_AP_PA.nii %s_ses-0%d_nodif_PA.nii 3 1', chemin_derivatives_DTI, liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession));
    
    % on concatene les deux images nodifs nodif_PA et nodif_AP en un fichier 4D utilise ulterieurement
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ;fslmerge -t %s_ses-0%d_nodifs_AP_PA.nii %s/%s_ses-0%d_nodif_AP.nii %s/%s_ses-0%d_nodif_PA.nii',liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI, liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI, liste_sujets_pepsy{i},numsession));
    
    % on cree un fichier qui contient les infos avec les directions de
    % phase d encodage des deux images 0, 1 ou -1, 0, 0.0665 les trois
    % 1eres valeurs correspondent au vecteur qui specifie la direction de
    % la phase d encogage ou 1 correspond a la phase d encodage dans la
    % direction y (A vers P) = phase positive et -1 (P vers A) = phase
    % negative, 0.0469 = readout_time = effective echo spacing (ms) * (pour
    % phillips)
    param_AP = ('0 1 0 0.0469');
    param_PA = ('0 -1 0 0.0469'); 
    unix(sprintf('(echo %s ; echo %s) > %s_ses-0%d_acqparams.txt', param_AP, param_PA,liste_sujets_pepsy{i},numsession));
    
    % on cree le champs de deformation
    % --imain = iamge 4D de tous les nodifs
    % --datain = nom du fichier texte des parametres d acqui des images nodif AP et PA
    % --config = fichier de config
    % --out = nom du fichier de sortie generant une iamge contenant les coeff de spline encodant le champ de non resonance (my_topup_results_fieldcoef.nii) et un fichier texte avec les parametres de mouvement du sujet (my_topup_results_movpar.txt)
    % --fout = nom du fichier de sortie generant une image du champ estime en HZ
    % --iout = nom du fichier de sortie generant une image 4D des images non deformees et corrigees des mvts
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; topup --imain=%s/%s_ses-0%d_nodifs_AP_PA.nii --datain=%s/%s_ses-0%d_acqparams.txt --config=b02b0.cnf --out=%s_ses-0%d_my_topup_results --fout=%s_ses-0%d_my_field --iout=%s_ses-0%d_my_hifi_nodifs',chemin_derivatives_DTI, liste_sujets_pepsy{i},numsession, chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession));
    
    % on applique le champs de deformation aux images AP et PA
    % genere un fichier 4D contenant les images AP (nodif et DTI) corrigees (si on veut celles PA --imain=...PA.nii,...AP.nii)
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; applytopup --imain=%s/%s_ses-0%d_dir-AP_epi.nii.gz,%s/%s_ses-0%d_dir-PA_epi.nii.gz --inindex=1,2 --datain=%s/%s_ses-0%d_acqparams.txt --topup=%s/%s_ses-0%d_my_topup_results --out=%s_ses-0%d_my_EPIC_images',chemin_dataset_fmap, liste_sujets_pepsy{i},numsession,chemin_dataset_fmap, liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession));
    
    %% etape 2 = corrections des mouvements de la tete des participants et des courants de foucaults (CF) induits par le switch des gradients (champs magnetique) produisant de fortes distorsions geometriques
    %correction utilisant une transformation affine lineaire (FLIRT) a un volume de ref (nodif)
    
    % chemin pour recuperer les images d interets (DTI) dans le dataset dwi
    chemin_dataset_dwi = (sprintf('/homes_unix/quinton/Documents/PEPsy/dataset/%s/ses-0%d/dwi',liste_sujets_pepsy{i},numsession));
 
     % on designe le nom des fichiers d interets bvec et bval
    bvecs = (sprintf('%s/%s_ses-0%d_dwi.bvec',chemin_dataset_dwi,liste_sujets_pepsy{i},numsession));
    bvals = (sprintf('%s/%s_ses-0%d_dwi.bval',chemin_dataset_dwi,liste_sujets_pepsy{i},numsession));
    
    
    % on moyenne a travers le temps les deux images nodifs des sequences AP et PA de l etape precedente afin de generer un mask_nodif (nodifs_AP_PA_mean_brain_mask) cad un mask binaire du cerveau (f = seuil par defaut = 0.2) utilise pour la suite des pretraitements
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; fslmaths %s/%s_ses-0%d_my_hifi_nodifs.nii -Tmean %s_ses-0%d_nodifs_AP_PA_mean.nii', chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession));
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; bet %s/%s_ses-0%d_nodifs_AP_PA_mean.nii %s_ses-0%d_nodifs_AP_PA_mean_brain -m -f 0.2', chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession));
    
    % la fonction cree la meme image que celle du nodif donc on l a supprime
    unix(sprintf('rm %s/%s_ses-0%d_nodifs_AP_PA_mean_brain.nii', chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession));
    
    % corrections en simultanees des mvts de la tete, des CF et des distorsions EPI via la commande suivante (interpolation par defaut = trilineaire)
    % attention l image 4D des data DTI (composee de 49 volumes dont 48 images de direction et 1 image nodif) situe le nodif en dernier volume via dcm2bids
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; eddy_openmp --imain=%s/%s_ses-0%d_dwi.nii --mask=%s/%s_ses-0%d_nodifs_AP_PA_mean_brain_mask --index=/homes_unix/quinton/Documents/index_dwi.txt --acqp=%s/%s_ses-0%d_acqparams.txt --bvecs=%s --bvals=%s --topup=%s/%s_ses-0%d_my_topup_results --data_is_shelled --out=%s/%s_ses-0%d_eddy_corrected_data_dti', chemin_dataset_dwi,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession, bvecs, bvals, chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession));
    
    % Ajustement du modele de tenseur a chaque voxel sur les data corrigees precedement (k = data dti corrigees en 4D incluant les volumes avec et sans ponderation; m = mask du cerveau binarise issu du bet image en 3D cerveau = 1 le reste = 0; 0 = fichier de sortie; r = fichier bvec fichier qui contient la liste des directions de gradients : l ordre doit matcher avec l ordre des volumes de l image 4D format fichier) et calcul des metrics DTI
    % dtifit ne calcul que FA/MD/L1/L2/L3.. mais pas RD
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; dtifit -k %s/%s_ses-0%d_eddy_corrected_data_dti -m %s/%s_ses-0%d_nodifs_AP_PA_mean_brain_mask -r %s -b %s -o %s/%s_ses-0%d_EC_dtifit --save_tensor --verbose',chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession, bvecs, bvals, chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession));
    
    %calcul de la RD
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; fslmaths %s/%s_ses-0%d_EC_dtifit_L2 -add %s/%s_ses-0%d_EC_dtifit_L3 -div 2 %s/%s_ses-0%d_EC_dtifit_RD',chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession));

   cd(WORKINGPATH);

end