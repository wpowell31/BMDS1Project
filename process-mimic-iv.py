import pandas as pd


# Set filenames
patients_filename = '/Users/willpowell/Desktop/BMDS1/mimic-iv/patients.csv.gz'
prescriptions_filename = '/Users/willpowell/Desktop/BMDS1/mimic-iv/prescriptions.csv.gz'
admissions_filename = '/Users/willpowell/Desktop/BMDS1/mimic-iv/admissions.csv.gz'   
icustays_filename = '/Users/willpowell/Desktop/BMDS1/mimic-iv/icustays.csv.gz'
diagnoses_icd_filename = '/Users/willpowell/Desktop/BMDS1/mimic-iv/diagnoses_icd.csv.gz'

# Read in data
patients = pd.read_csv(patients_filename)
prescriptions = pd.read_csv(prescriptions_filename)
admissions = pd.read_csv(admissions_filename)
icustays = pd.read_csv(icustays_filename)
diagnoses_icd = pd.read_csv(diagnoses_icd_filename)

# rename admissions language column to lang
admissions.rename(columns={'language': 'lang'}, inplace=True)

# drop columns from prescriptions
prescriptions = prescriptions[['subject_id', 'hadm_id', 'ndc']]

# Save data
patients.to_csv('/Users/willpowell/Desktop/BMDS1/mimic-iv/patients.csv', index=False)
prescriptions.to_csv('/Users/willpowell/Desktop/BMDS1/mimic-iv/prescriptions.csv', index=False)
admissions.to_csv('/Users/willpowell/Desktop/BMDS1/mimic-iv/admissions.csv', index=False)
icustays.to_csv('/Users/willpowell/Desktop/BMDS1/mimic-iv/icustays.csv', index=False)
diagnoses_icd.to_csv('/Users/willpowell/Desktop/BMDS1/mimic-iv/diagnoses_icd.csv', index=False)