#!/usr/bin/env python
"""gen_data_files.py

 
Usage:
  gen_data_files.py  <path_to_config_files> <path_to_annotation> <path_to_recipe>
  gen_data_files.py  --help

Options:
  <path_to_config_files>  Path to config files 
  <path_to_annotation>    Path to annotation files
  <path_to_recipe>        Path to Kaldi's project recipe. 
  --help                  Print this help screen
"""

import docopt
import csv
import data_info_files as dif

def recipe_data(path_to_config_files, path_to_annotation, path_to_recipe):
    chunks_files = dif.read_file(path_to_config_files+"/chunks_files.txt")
    train_chunk = dif.read_file(path_to_config_files+"/train_chunk.txt")
    test_chunk = dif.read_file(path_to_config_files+"/test_chunk.txt")
    mod = dif.read_file(path_to_config_files+"/mod.txt")

    mods = {}
    reader = csv.DictReader(mod, fieldnames=['mod', 'activate'])

    spk_train = set()
    spk_test = set ()

    for row in reader:
        mods[row['mod']] = int(row['activate'])

    if mods['pitch'] == 1:
        spk_train = dif.speaker_data(spk_train, chunks_files, train_chunk, 'P')

    spk_train = dif.speaker_data(spk_train, chunks_files, train_chunk, 'N')
    spk_test = dif.speaker_data(spk_test, chunks_files, test_chunk, 'N')

    text_train = dif.gen_text_files('N', path_to_annotation, path_to_recipe, spk_train)
    text_test  = dif.gen_text_files('N', path_to_annotation, path_to_recipe, spk_test)


    if mods['pitch']==1 and mods['tempo']==1 and mods['combination']==1:
        text_train_p = dif.gen_text_files('C', path_to_annotation, path_to_recipe, spk_train)
        text_train = text_train + text_train_p
    else:
        if mods['pitch']==1:
            text_train_p = dif.gen_text_files('P', path_to_annotation, path_to_recipe, spk_train)
            text_train = text_train + text_train_p
        if mods['tempo']==1:
            text_train_p = dif.gen_text_files('T', path_to_annotation, path_to_recipe, spk_train)
            text_train = text_train + text_train_p


    wav_scp_train, utt2spk_train = dif.gen_wavscp_utt2spk_files(text_train)
    wav_scp_test, utt2spk_test = dif.gen_wavscp_utt2spk_files(text_test)
    
    spk2gender_train = dif.gen_spk2gen(spk_train)
    spk2gender_test = dif.gen_spk2gen(spk_test)   

    with open(path_to_recipe + '/data/train/spk2gender', 'wb') as f:
        f.write("\n".join(spk2gender_train))
    with open(path_to_recipe + '/data/test/spk2gender', 'wb') as f:
        f.write("\n".join(spk2gender_test))
    
    with open(path_to_recipe + '/data/train/wav.scp', 'wb') as f:
        f.write("\n".join(wav_scp_train))
    with open(path_to_recipe + '/data/test/wav.scp', 'wb') as f:
        f.write("\n".join(wav_scp_test))     

    with open(path_to_recipe + '/data/train/text', 'wb') as f:
        f.write("\n".join(text_train))
    with open(path_to_recipe + '/data/test/text', 'wb') as f:
        f.write("\n".join(text_test))    
    
    with open(path_to_recipe + '/data/train/utt2spk', 'wb') as f:
        f.write("\n".join(utt2spk_train))
    with open(path_to_recipe + '/data/test/utt2spk', 'wb') as f:
        f.write("\n".join(utt2spk_test))      
   
      


def main():
    """Main method called from commandline."""
    arguments = docopt.docopt(__doc__)
    path_to_config_files = arguments['<path_to_config_files>']
    path_to_annotation = arguments['<path_to_annotation>']
    path_to_recipe = arguments['<path_to_recipe>']

    
    recipe_data(path_to_config_files, path_to_annotation, path_to_recipe)
    


if __name__ == '__main__':
    main()


