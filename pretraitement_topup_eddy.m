WORKINGPATH = '/homes_unix/quinton/Documents/PEPsy/derivatives/';
cd(WORKINGPATH);
liste_sujets_pepsy  = textread('/homes_unix/quinton/Documents/list_subject_pepsy.txt', '%s');
nsubj = numel(liste_sujets_pepsy);
numsession = 1;

for i=2
   
    fprintf('Sujets: %s\n ',liste_sujets_pepsy{i});
    
chemin_dataset_fmap = (sprintf('/homes_unix/quinton/Documents/PEPsy/dataset/%s/ses-0%d/fmap',liste_sujets_pepsy{i},numsession));
chemin_dataset_dwi = (sprintf('/homes_unix/quinton/Documents/PEPsy/dataset/%s/ses-0%d/dwi',liste_sujets_pepsy{i},numsession));
chemin_derivatives_DTI = (sprintf('%s%s/ses-0%d/DTI',WORKINGPATH,liste_sujets_pepsy{i},numsession));

end

cd(WORKINGPATH);

for i=2
    fprintf('Sujets: %s\n pretraitement DTI',liste_sujets_pepsy{i});
    
    unix(sprintf('mkdir %s', liste_sujets_pepsy{i}));
    cd(liste_sujets_pepsy{i});
    
    unix(sprintf('mkdir ses-0%d', numsession));
    cd(sprintf('ses-0%d', numsession));
    
    unix('mkdir DTI');
    cd('DTI');
    
    chemin_derivatives_DTI = (sprintf('%s%s/ses-0%d/DTI',WORKINGPATH,liste_sujets_pepsy{i},numsession));
    chemin_dataset_fmap = (sprintf('/homes_unix/quinton/Documents/PEPsy/dataset/%s/ses-0%d/fmap',liste_sujets_pepsy{i},numsession));

     unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ;fslmerge -t %s_ses-0%d_all_AP_PA.nii %s/%s_ses-0%d_dir-AP_epi.nii.gz %s/%s_ses-0%d_dir-PA_epi.nii.gz',liste_sujets_pepsy{i},numsession, chemin_dataset_fmap, liste_sujets_pepsy{i},numsession, chemin_dataset_fmap, liste_sujets_pepsy{i},numsession));
     unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; fslroi %s/%s_ses-0%d_all_AP_PA.nii %s_ses-0%d_nodif_AP.nii 1 1', chemin_derivatives_DTI, liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession));
     unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; fslroi %s/%s_ses-0%d_all_AP_PA.nii %s_ses-0%d_nodif_PA.nii 3 1', chemin_derivatives_DTI, liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession));
     unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ;fslmerge -t %s_ses-0%d_nodifs_AP_PA.nii %s/%s_ses-0%d_nodif_AP.nii %s/%s_ses-0%d_nodif_PA.nii',liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI, liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI, liste_sujets_pepsy{i},numsession));
    
    param_AP = ('0 1 0 0.0469');
    param_PA = ('0 -1 0 0.0469'); 
    unix(sprintf('(echo %s ; echo %s) > %s_ses-0%d_acqparams.txt', param_AP, param_PA,liste_sujets_pepsy{i},numsession));
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; topup --imain=%s/%s_ses-0%d_nodifs_AP_PA.nii --datain=%s/%s_ses-0%d_acqparams.txt --config=b02b0.cnf --out=%s_ses-0%d_my_topup_results --fout=%s_ses-0%d_my_field --iout=%s_ses-0%d_my_hifi_nodifs',chemin_derivatives_DTI, liste_sujets_pepsy{i},numsession, chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession));
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; applytopup --imain=%s/%s_ses-0%d_dir-AP_epi.nii.gz,%s/%s_ses-0%d_dir-PA_epi.nii.gz --inindex=1,2 --datain=%s/%s_ses-0%d_acqparams.txt --topup=%s/%s_ses-0%d_my_topup_results --out=%s_ses-0%d_my_EPIC_images',chemin_dataset_fmap, liste_sujets_pepsy{i},numsession,chemin_dataset_fmap, liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession));
    
    chemin_dataset_dwi = (sprintf('/homes_unix/quinton/Documents/PEPsy/dataset/%s/ses-0%d/dwi',liste_sujets_pepsy{i},numsession));
 
    bvecs = (sprintf('%s/%s_ses-0%d_dwi.bvec',chemin_dataset_dwi,liste_sujets_pepsy{i},numsession));
    bvals = (sprintf('%s/%s_ses-0%d_dwi.bval',chemin_dataset_dwi,liste_sujets_pepsy{i},numsession));
    
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; fslmaths %s/%s_ses-0%d_my_hifi_nodifs.nii -Tmean %s_ses-0%d_nodifs_AP_PA_mean.nii', chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession));
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; bet %s/%s_ses-0%d_nodifs_AP_PA_mean.nii %s_ses-0%d_nodifs_AP_PA_mean_brain -m -f 0.2', chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,liste_sujets_pepsy{i},numsession));
    unix(sprintf('rm %s/%s_ses-0%d_nodifs_AP_PA_mean_brain.nii', chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession));
    
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; eddy_openmp --imain=%s/%s_ses-0%d_dwi.nii --mask=%s/%s_ses-0%d_nodifs_AP_PA_mean_brain_mask --index=/homes_unix/quinton/Documents/index_dwi.txt --acqp=%s/%s_ses-0%d_acqparams.txt --bvecs=%s --bvals=%s --topup=%s/%s_ses-0%d_my_topup_results --data_is_shelled --out=%s/%s_ses-0%d_eddy_corrected_data_dti', chemin_dataset_dwi,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession, bvecs, bvals, chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession));
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; dtifit -k %s/%s_ses-0%d_eddy_corrected_data_dti -m %s/%s_ses-0%d_nodifs_AP_PA_mean_brain_mask -r %s -b %s -o %s/%s_ses-0%d_EC_dtifit --save_tensor --verbose',chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession, bvecs, bvals, chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession));
    unix(sprintf('setenv FSLOUTPUTTYPE NIFTI ; fslmaths %s/%s_ses-0%d_EC_dtifit_L2 -add %s/%s_ses-0%d_EC_dtifit_L3 -div 2 %s/%s_ses-0%d_EC_dtifit_RD',chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession,chemin_derivatives_DTI,liste_sujets_pepsy{i},numsession));

   cd(WORKINGPATH);

end