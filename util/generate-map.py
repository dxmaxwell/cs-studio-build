#!/usr/bin/python

import os, sys, os.path, zipfile

from datetime import datetime

from optparse import OptionParser

from xml.etree import ElementTree


parser = OptionParser()

parser.add_option("--tag", help="Specify a repository 'tag'. Useful for source repositories (ie GIT)")

parser.add_option("--repo", help="Specify the location of the repository with a URL")

parser.add_option("--path", help="Specify a base path for the elements. Useful for GIT repositories")

parser.add_option("--format", help="Specify the output format (GIT, P2)", default="p2")

(options, args) = parser.parse_args()


if len(args) == 0:
    srcDirectories = [ os.getcwd() ]
else:
    srcDirectories = args

if options.tag == None:
    options.tag = "origin/master"

if options.repo == None:
    options.repo = "file:/" + os.getcwd()

options.format = options.format.lower()

if options.format not in [ "git", "p2", "p2iu", "json" ]:
    sys.stderr.write( "Error: Format specified, %s, not supported.\n" % options.format )
    sys.exit( 1 )



def getFeatureInfo( featureFile ):
    if featureFile == None:
        return None
    
    featureTree = ElementTree.parse( featureFile )
    featureFile.close()
    if not featureTree:
        return None

    featureRoot = featureTree.getroot()
    return ( "feature", featureRoot.attrib["id"], featureRoot.attrib["version"] )


def getManifestInfo( manifestFile ):
    if manifestFile == None:
        return None

    elementType = "plugin"
    bundleVersion = None
    bundleSymbolicName = None

    for line in manifestFile:

        prop = line.split(":", 2)
        if len(prop) < 2:
            continue

        name = prop[0].strip().lower()
        values = prop[1].split(";")

        if name == "fragment-host":
            elementType = "fragment"

        if name == "bundle-version":
            bundleVersion = values[0].strip()

        if name == "bundle-symbolicname":
            bundleSymbolicName = values[0].strip()

    manifestFile.close();

    return ( elementType, bundleSymbolicName, bundleVersion )



def getElementInfo( elementPath ):

    if os.path.isdir( elementPath ):

        # If it has a feature.xml file, then it must be a feature.
        featurePath = os.path.join( elementPath, "feature.xml" )
        try:
            featureFile = open( featurePath, "r" )
        except:
            featureFile = None

        featureInfo = getFeatureInfo( featureFile )
        if featureInfo:
            return featureInfo

        # If is has a MANIFEST.MF file, then it must be a plugin or fragment.
        manifestPath = os.path.join( elementPath, "META-INF", "MANIFEST.MF" )
        try:
            manifestFile = open( manifestPath, "r" )
        except:
            manifestFile = None

        manifestInfo = getManifestInfo( manifestFile )
        if manifestInfo:
            return manifestInfo
    

    # Handle if bundle is packaged as JAR.
    if zipfile.is_zipfile( elementPath ):
        jarFile = zipfile.ZipFile( elementPath )

        # If it has a feature.xml file, then it must be a feature.
        featurePath = "feature.xml"
        try:
            featureFile = jarFile.open( featurePath, "r" )
        except:
            featureFile = None

        featureInfo = getFeatureInfo( featureFile )
        if featureInfo:
            return featureInfo

        # If is has a MANIFEST.MF file, then it must be a plugin or fragment.
        manifestPath = "META-INF/MANIFEST.MF"
        try:
            manifestFile = jarFile.open( manifestPath, "r" )
        except:
            manifestFile = None

        manifestInfo = getManifestInfo( manifestFile )
        if manifestInfo:
            return manifestInfo

    return None    


firstWrite = True;

def writeP2IU( elmInfo ):

    if elmInfo[0] == "plugin":
        sys.stdout.write("plugin@")
        sys.stdout.write(elmInfo[1])
        sys.stdout.write(",")
        sys.stdout.write(elmInfo[2])
        sys.stdout.write("=p2IU,id=")
        sys.stdout.write(elmInfo[1])
        sys.stdout.write(",version=")
        sys.stdout.write(elmInfo[2])
        sys.stdout.write(",repository=")
        sys.stdout.write(options.repo)
        sys.stdout.write("\n\n")

    elif elmInfo[0] == "feature":
        sys.stdout.write("feature@")
        sys.stdout.write(elmInfo[1])
        sys.stdout.write(",")
        sys.stdout.write(elmInfo[2])
        sys.stdout.write("=p2IU,id=")
        sys.stdout.write(elmInfo[1])
        sys.stdout.write(".feature.jar,version=")
        sys.stdout.write(elmInfo[2])
        sys.stdout.write(",repository=")
        sys.stdout.write(options.repo)
        sys.stdout.write("\n\n")

    elif elmInfo[0] == "fragment":
        sys.stdout.write("fragment@")
        sys.stdout.write(elmInfo[1])
        sys.stdout.write(",")
        sys.stdout.write(elmInfo[2])
        sys.stdout.write("=p2IU,id=")
        sys.stdout.write(elmInfo[1])
        sys.stdout.write(",version=")
        sys.stdout.write(elmInfo[2])
        sys.stdout.write(",repository=")
        sys.stdout.write(options.repo)
        sys.stdout.write("\n\n")

    else:
        sys.stderr.write( "Error: Unable to write element in p2IU format: %s: of type: %s\n" % (elmPath, elmInfo[0]) )



def writeGIT( elmPath, elmInfo ):
    
    if options.path == None:
        path = elmPath
    else:
        path = os.path.join( option.path, elmPath )

    if elmInfo[0] == "plugin":
        sys.stdout.write("plugin@")
        sys.stdout.write(elmInfo[1])
        sys.stdout.write("=GIT,tag=")
        sys.stdout.write(options.tag)
        sys.stdout.write(",repo=")
        sys.stdout.write(options.repo)
        sys.stdout.write(",path=")
        sys.stdout.write(path)
        sys.stdout.write("\n\n")
    
    elif elmInfo[0] == "feature":
        sys.stdout.write("feature@")
        sys.stdout.write(elmInfo[1])
        sys.stdout.write("=GIT,tag=")
        sys.stdout.write(options.tag)
        sys.stdout.write(",repo=")
        sys.stdout.write(options.repo)
        sys.stdout.write(",path=")
        sys.stdout.write(path)
        sys.stdout.write("\n\n")

    elif elmInfo[0] == "fragment":
        sys.stdout.write("fragment@")
        sys.stdout.write(elmInfo[1])
        sys.stdout.write("=GIT,tag=")
        sys.stdout.write(options.tag)
        sys.stdout.write(",repo=")
        sys.stdout.write(options.repo)
        sys.stdout.write(",path=")
        sys.stdout.write(path)
        sys.stdout.write("\n\n")

    else:
        sys.stderr.write( "Error: Unable to write element in GIT format: %s: of type: %s\n" % (elmPath, elmInfo[0]) )


def writeJSON( elmInfo ):

    if options.path == None:
        path = elmPath
    else:
        path = os.path.join( option.path, elmPath )

    global firstWrite

    if firstWrite:
        sys.stdout.write("\n\n{ \"")
        firstWrite = False
    else:
        sys.stdout.write(",\n\n{ \"")
    sys.stdout.write(elmInfo[0])
    sys.stdout.write("\":{\"id\":\"")
    sys.stdout.write(elmInfo[1])
    sys.stdout.write("\",\"version\":\"")
    sys.stdout.write(elmInfo[2])
    sys.stdout.write("\"}}")



if options.format in [ "git", "p2", "p2iu" ]:
    sys.stdout.write( "!*** This file was generated on %s\n\n" % (datetime.now().strftime("%B %d, %Y %I:%M:%S %p %Z"),) )
elif options.format in [ "json" ]:
    sys.stdout.write("{ \"generated\":\"%s\", \"map\":[" % (datetime.now().strftime("%B %d, %Y %I:%M:%S %p %Z"),) )


for srcDirectory in srcDirectories:

    if not os.path.isdir( srcDirectory ):
        sys.stderr.write( "Error: Source directory not found: %s\n" % (srcDirectory,) )
        continue


    for element in os.listdir( srcDirectory ):
        elmPath = os.path.join( srcDirectory, element)
        elmInfo = getElementInfo( elmPath )
        if elmInfo == None:
            sys.stderr.write( "Error: Unable to get information for element: %s\n" % (element,) )

        elif options.format in [ "git" ]:
            writeGIT( elmPath, elmInfo )

        elif options.format in [ "p2", "p2iu" ]:
            writeP2IU( elmInfo )

        elif options.format in [ "json" ]:
            writeJSON( elmInfo )


if options.format in [ "json" ]:
    sys.stdout.write("\n\n]}")

sys.exit( 0 )
