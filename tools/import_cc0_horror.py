"""Korku anlarının gerçek kayıtlı CC0 sesleri.

Kaynaklar (hepsi CC0 1.0, OpenGameArt):
- "Horror Hit Soundpack 1" (psychhead_)
- "Monster or beast sounds" (pauliuw)
- "Ambient horror" (techiew)
- "Abandoned passages (horror ambience loop)" (congusbongus)

Kullanım: python3 -I tools/import_cc0_horror.py <kaynak_klasörü> <assets/audio>
Yardımcılar tools/import_cc0.py'den alınır.
"""
import os
import sys

sys.argv = [sys.argv[0], sys.argv[1], sys.argv[2]]
here = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(here, 'import_cc0.py'), encoding='utf-8').read()
exec(src.split('one = lambda name:')[0])   # yalnızca yardımcılar

one = lambda name: fade(silence_trim(load(name)))

# Korku vurgusu: çok bas bir vuruş, gecikmeli bir yaratık hırıltısı.
hit = silence_trim(load('Very Bassy 3.wav'))
growl = silence_trim(load('Beast Growl 3.wav'))
save('sting', fade(trim(mix((hit, 0, 1.0), (growl, 0.12, 0.5)), 0, 3.8), 0.002, 0.9), 0.85)
# Karanlıkta beliren gözler: alçak bir hırıltı.
save('growl', fade(silence_trim(load('Beast Growl 4.wav')), 0.01, 0.6), 0.6)
# Karabasan kovalamacası: koro ve çığlıklı korku ortamı, dikişsiz döngü.
save('karabasan', loop(load('ambient_horror.ogg'), 2.5), 0.85)
# Derinkuyu: dar, karanlık geçit (kendisi dikişsiz döngü).
save('amb_cave', load('freezer.ogg'), 0.5)
