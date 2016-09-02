#!/usr/bin/env python
"""data_info_files.py

Tool that generate the Kaldi's files;
    spk2gender  <speaker ID> <gender>
    wav.scp     <utteranceID> <full_path_to_audio_file> 
    text        <utteranceID> <text_transcription>
    utt2spk     <utteranceID> <speakerID>

Requirements:
Prepare the config files;
    chunks_files.txt with fullpath to each cover_chunk file 
    train_chunk.txt with the numbers of the chunks will be used for training
    test_chunk.txt with the numbers of the chunks will be used for testing
    
Usage:
  data_info_files.py  <path_to_config_files> <path_to_annotation> <path_to_recipe> [--mod=<mod_flag>]
  data_info_files.py  --help

Options:
  <path_to_config_files>  Path to config files #
  <path_to_annotation>    Path to annotation files
  <path_to_recipe>        Path to Kaldi's project recipe. 
  --mod=<mod_flag>        Use only if the files are from mod data, Flags are P, T, C [default: N]
  --help                  Print this help screen

"""

import docopt
import os
import csv

def check_utterance_with_vocabulary(path_to_recipe, text):
    vocabulary = []
    with open(path_to_recipe + '/data/local/dict/lexicon.txt') as f:
        for line in f:
            vocabulary.append(line.split()[0])

    newlines = []

    for line in text:
        line2 = line[30:]
        line2=line2.replace('-', " ").replace(".", " ")
        delete = 0 
        for word in line2.split():
            if word not in vocabulary:
                #print word, line[:23]
                delete = 1
                break
        if delete == 0:
            newlines.append(line)
    
    return newlines
        

def read_file(source_file):
    source_list = []
    with open(source_file) as f:
       for line in f:
           if line[0] != '#':
               source_list.append(line.replace("\n",""))
    return source_list
    

def read_text(path, speaker, mod):
    text = []
    spk = list(speaker)
    speaker = set()
    for s in spk:
        speaker.add(s[:7])
    for root, dirs, files in os.walk(path, topdown=True):
        for fil in files:
            if fil[:4]+ "_" + fil[9:11] in speaker:
                if mod =='N' and fil[12:16]=='0101': 
                    with open(root + '/' + fil) as f:
                        for index, line in enumerate(f):
                            line = line.replace(',', ' ').replace('"', '').replace('-',' ').strip()
                            spk = line[:4]+ "_" + line[9:11] + "_" + line[12:14]
                            line = spk + line[4:]
                            text.append(line.upper())
                elif mod == 'P' and fil[12:16] in ('0201', '0301'):
                    with open(root + '/' + fil) as f:
                        for index, line in enumerate(f):
                            line = line.replace(',', ' ').replace('"', '').replace('-',' ').strip()
                            spk = line[:4] + "_" + line[9:11] + "_" + line[12:14]
                            line = spk + line[4:]
                            text.append(line.upper())
                elif mod == 'T' and fil[12:16] in ('0102', '0103'):
                    with open(root + '/' + fil) as f:
                        for index, line in enumerate(f):
                            line = line.replace(',', ' ').replace('"', '').replace('-',' ').strip()
                            spk = line[:4] + "_" + line[9:11] + "_" + line[12:14]
                            line = spk + line[4:]
                            text.append(line.upper())
                elif mod == 'C':
                    with open(root + '/' + fil) as f:
                        for index, line in enumerate(f):
                            line = line.replace(',', ' ').replace('"', '').replace('-',' ').strip()
                            spk = line[:4] + "_" + line[9:11] + "_" + line[12:14]
                            line = spk + line[4:]
                            text.append(line.upper())

    return text


def speaker_data(spk, chunks_files, chunk_list, mod):
    #spk = set()

    for cf in range(len(chunks_files)):
        with open(chunks_files[cf]) as csvfile:
            reader = csv.DictReader(csvfile, fieldnames=['id', 'link','cartist','track','instrument','pitch','tempo','chunk'])
            for row in reader:
                cartist = row['id'][:4]+ "_" + row['id'][9:11]
                row_chunk = row['chunk'][3:]
                if row_chunk in chunk_list:
                    if mod == 'N':
                        spk.add(cartist + "_" + '01')
                    if mod == 'P':
                        spk.add(cartist + "_" + '02')
                        spk.add(cartist + "_" + '03')



                    
    return spk


def gen_text_files(mod, path_to_annotation, path_to_recipe, speaker):
    
    if mod == 'N':
        path = path_to_annotation +"/text/"
        text = read_text(path, speaker, mod)
    else:
        path = path_to_annotation + "/text_mod/"
        text  = read_text(path, speaker, mod)
    text = check_utterance_with_vocabulary(path_to_recipe, text)

    return text


def gen_wavscp_utt2spk_files(text):
    wav_scp = []
    utt2spk = []

    for line in text:
        if line[18:22] == '0101':
            path_audio = "wav/wav_segments/"
        else:
            path_audio ="wav/wav_modifications/"

        wav_scp.append(line[:29] \
                       + " " + path_audio + line[0] + "/" + line[:4] + "/" + line.split()[0][:5]+line.split()[0][11:] + ".wav")
        utt2spk.append(line[:29] \
                       + " " + line[:10])
        #wav_scp.append(line.split()[0] + " " + path_audio + \
        #    line[0] + "/" + line[:4] + "/" + line.split()[0] + ".wav")
        #utt2spk.append(line.split()[0] + " " + line[:4]+ "_" + line[9:11] + "_" + line[12:14])


    return wav_scp, utt2spk
    

def gen_spk2gen(speaker):
    spk2gender = []
    for spk in speaker:
        spk2gender.append(spk + " " + spk[0].lower())
    
    return spk2gender
    
def main():
    """Main method called from commandline."""
    arguments = docopt.docopt(__doc__)
    path_to_config_files = arguments['<path_to_config_files>']
    path_to_annotation = arguments['<path_to_annotation>']
    path_to_recipe = arguments['<path_to_recipe>']
    mod = arguments['--mod'].upper()
    
    chunks_files = read_file(path_to_config_files+"chunks_files.txt")
    train_chunk = read_file(path_to_config_files+"train_chunk.txt")
    test_chunk = read_file(path_to_config_files+"test_chunk.txt")
    
    spk_train, spk_test = speaker_data(chunks_files, train_chunk, test_chunk, mod)
 
    text_train = gen_text_files(mod, path_to_annotation, path_to_recipe, spk_train)
    text_test  = gen_text_files(mod, path_to_annotation, path_to_recipe, spk_test)

    wav_scp_train, utt2spk_train = gen_wavscp_utt2spk_files(mod, text_train)
    wav_scp_test, utt2spk_test = gen_wavscp_utt2spk_files(mod, text_test)     
    
    spk2gender_train = gen_spk2gen(spk_train)
    spk2gender_test = gen_spk2gen(spk_test)
    
    
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
    


if __name__ == '__main__':
    main()
