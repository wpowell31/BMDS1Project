import pandas as pd
import requests
import json

# First get RXCUIs for Opioids of interest
opioids = [
    'buprenorphine',
    'fentanyl',
    'hydrocodone',
    'meperidine',
    'methadone',
    'morphine',
    'oxycodone',
    'oxymorphone',
    'tramadol'
]

def get_rxcuis_from_json(data):
    '''
    Extract list of rxcuis from json data
    Parameters:
    -----------
    data: json() object that is the output of the RXNORM getDrugs API
    
    Returns:
    --------
    rxcuis: a list of the all the rxcuis (as characters) associated with that drug name
    '''
    
    if('conceptGroup' not in data['drugGroup']):
        return None
    rxcuis = []
    concept_group = data['drugGroup']['conceptGroup']
    for i in range(len(concept_group)):
        drug_tty = concept_group[i]
        if('conceptProperties' in drug_tty):
            drug_list = drug_tty['conceptProperties']
            for j in range(len(drug_list)):
                rxcui = drug_list[j]['rxcui']
                rxcuis.append(rxcui)
    return rxcuis


def get_rxcui_from_drug_name(drug_name):
    '''
    Get RXCUIs for a drug name
    Parameters:
    -----------
    drug_name: string, name of the drug
    
    Returns:
    --------
    rxcuis: a list of the all the rxcuis (as characters) associated with that drug name
    '''
    
    response = requests.get('https://rxnav.nlm.nih.gov/REST/drugs.json?name=' + drug_name)
    data = response.json()
    rxcuis = get_rxcuis_from_json(data)
    return rxcuis

def write_df_rxcuis(drug_names):
    '''
    Get RXCUIs for a list of drug names and write to a dataframe
    Parameters:
    -----------
    drug_names: a list of drug names
    
    Returns:
    --------
    df: a dataframe with drug names and rxcuis
    '''
    
    rxcuis_list = []
    drug_names_list = []
    for drug_name in drug_names:
        rxcuis = get_rxcui_from_drug_name(drug_name)
        for rxcui in rxcuis:
            rxcuis_list.append(rxcui)
            drug_names_list.append(drug_name)
    df = pd.DataFrame({'drug_name': drug_names_list, 'rxcui': rxcuis_list})
    return df

# Get RXCUIs for Opioids of interest
opioids_rxcuis = write_df_rxcuis(opioids)


# Get NDC codes for RXCUI
def get_ndc_from_rxcui(rxcui):
    '''
    Get NDC codes for a given RXCUI
    Parameters:
    -----------
    rxcui: string, RXCUI of the drug
    
    Returns:
    --------
    ndc_codes: a list of the all the ndc codes (as characters) associated with that drug rxcui
    '''
    
    response = requests.get('https://rxnav.nlm.nih.gov/REST/rxcui/' + rxcui + '/ndcs.json')
    data = response.json()
    if data['ndcGroup']['ndcList'] == {}:
        return ['None']
    ndc_codes = data['ndcGroup']['ndcList']['ndc']
    return ndc_codes

def write_df_ndcs(opioids_rxcuis):
    '''
    Get NDC codes for a list of RXCUIs and write to a dataframe
    Parameters:
    -----------
    opioids_rxcuis: a dataframe with drug names and rxcuis
    
    Returns:
    --------
    df: a dataframe with drug names, rxcuis and ndcs
    '''
    
    ndcs_list = []
    rxcuis_list = []
    drug_names_list = []
    for i in range(opioids_rxcuis.shape[0]):
        rxcui = opioids_rxcuis.iloc[i, 1]
        ndcs = get_ndc_from_rxcui(rxcui)
        for ndc in ndcs:
            ndcs_list.append(ndc)
            rxcuis_list.append(rxcui)
            drug_names_list.append(opioids_rxcuis.iloc[i, 0])
    df = pd.DataFrame({'drug_name': drug_names_list, 'rxcui': rxcuis_list, 'ndc': ndcs_list})
    return df

# Get NDC codes for Opioids of interest
opioids_ndcs = write_df_ndcs(opioids_rxcuis)


opioids_ndcs_clean = opioids_ndcs[opioids_ndcs['ndc'] != 'None']

opioids_ndcs_clean.to_csv(
    '/Users/willpowell/Desktop/BMDS1/mimic-iv/opioids_ndcs.csv', 
    index=False
)