#!/usr/bin/env python3


from distutils import file_util
import os,shutil
import csv,sqlite3



idx = {'de': "-de", 'en': ""}
for lang in ["de","en"]:
    infoplist = """<?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>CFBundleIdentifier</key>
        <string>speedatapublisheren</string>
        <key>CFBundleName</key>
        <string>speedata Publisher ({})</string>
        <key>DocSetPlatformFamily</key>
        <string>sp{}</string>
        <key>isDashDocset</key>
        <true/>
        <key>dashIndexFilePath</key>
        <string>index{}.html</string></dict>
    </plist>
    """.format(lang,lang,idx[lang])

    dir = 'build/speedatapublisher-{}.docset'.format(lang)
    shutil.rmtree(dir,ignore_errors=True)
    os.makedirs(dir + '/Contents/Resources/')
    f = open(dir + '/Contents/Info.plist', 'w')
    f.write(infoplist)

    shutil.copytree("build/manual/", dir + "/Contents/Resources/Documents")

    conn = sqlite3.connect(dir + '/Contents/Resources/docSet.dsidx'.format(lang))
    c = conn.cursor()
    c.execute('''CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);''')

    with open('temp/messages-{}.csv'.format(lang), newline='') as csvfile:
        messages = csv.reader(csvfile, delimiter=',', quotechar='"')
        for row in messages:
            c.execute("""INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (?, ?, ?);""",row)

    conn.commit()
    conn.close()
