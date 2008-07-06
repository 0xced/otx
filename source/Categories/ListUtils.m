/*
    ListUtils.m

    A category on Exe32Processor for linked list manipulation.

    This file is in the public domain.
*/

#import <Cocoa/Cocoa.h>

#import "ListUtils.h"

@implementation Exe32Processor(ListUtils)

// Each text line is stored in an element of a doubly-linked list. These are
// vanilla textbook funcs for maintaining the list.

//  insertLine:before:inList:
// ----------------------------------------------------------------------------

- (void)insertLine: (Line*)inLine
            before: (Line*)nextLine
            inList: (Line**)listHead
{
    if (!nextLine)
        return;

    if (nextLine == *listHead)
        *listHead   = inLine;

    inLine->prev    = nextLine->prev;
    inLine->next    = nextLine;
    nextLine->prev  = inLine;

    if (inLine->prev)
        inLine->prev->next  = inLine;
}

//  insertLine:after:inList:
// ----------------------------------------------------------------------------

- (void)insertLine: (Line*)inLine
             after: (Line*)prevLine
            inList: (Line**)listHead
{
    if (!prevLine)
    {
        *listHead   = inLine;
        return;
    }

    inLine->next    = prevLine->next;
    inLine->prev    = prevLine;
    prevLine->next  = inLine;

    if (inLine->next)
        inLine->next->prev  = inLine;
}

//  replaceLine:withLine:inList:
// ----------------------------------------------------------------------------
//  This non-standard method is used for merging the verbose and plain lists.

- (void)replaceLine: (Line*)inLine
           withLine: (Line*)newLine
             inList: (Line**)listHead
{
    if (!inLine || !newLine)
        return;

    if (inLine == *listHead)
        *listHead   = newLine;

    newLine->next   = inLine->next;
    newLine->prev   = inLine->prev;

    if (newLine->next)
        newLine->next->prev = newLine;

    if (newLine->prev)
        newLine->prev->next = newLine;

    if (inLine->chars)
        free(inLine->chars);

    free(inLine);
}

//  printLinesFromList:
// ----------------------------------------------------------------------------
//  Print our modified lines to a FILE*. The FILE* is a real file in the GUI
//  target, and stdout in the CLI target.

- (BOOL)printLinesFromList: (Line*)listHead
{
    FILE* outFile = NULL;

    // In the CLI target, mOutputFilePath is nil.
    if (iOutputFilePath)
    {
        const char* outPath = UTF8STRING(iOutputFilePath);
        outFile = fopen(outPath, "w");
    }
    else
        outFile = stdout;

    if (!outFile)
    {
        perror("otx: unable to open output file");
        return NO;
    }

    Line*   theLine = listHead;

    // Cache the fileno and use SYS_write for maximum speed.
    SInt32  fileNum = fileno(outFile);

    while (theLine)
    {
        if (syscall(SYS_write, fileNum, theLine->chars, theLine->length) == -1)
        {
            perror("otx: unable to write to output file");

            if (iOutputFilePath)
            {
                if (fclose(outFile) != 0)
                    perror("otx: unable to close output file");
            }

            return NO;
        }

        theLine = theLine->next;
    }

    if (iOutputFilePath)
    {
        if (fclose(outFile) != 0)
        {
            perror("otx: unable to close output file");
            return NO;
        }
    }

    return YES;
}

//  deleteLinesFromList:
// ----------------------------------------------------------------------------

- (void)deleteLinesFromList: (Line*)listHead
{
    Line*   theLine = listHead;

    while (theLine)
    {
        if (theLine->prev)              // If there's one behind us...
        {
            free(theLine->prev->chars); // delete it.
            free(theLine->prev);
        }

        if (theLine->next)              // If there are more...
            theLine = theLine->next;    // jump to next one and continue.
        else
        {                               // This is the last one, delete it.
            free(theLine->chars);
            free(theLine);
            theLine = NULL;
        }
    }
}

//  deleteLinesBefore:fromList:
// ----------------------------------------------------------------------------

- (void)deleteLinesBefore: (Line*)inLine
                 fromList: (Line**)listHead
{
    Line*   theLine = *listHead;

    while (theLine)
    {
        if (theLine->prev)              // If there's one behind us...
        {
            free(theLine->prev->chars); // delete it.
            free(theLine->prev);
        }

        if (theLine->next && theLine->next != inLine)   // If there are more...
            theLine = theLine->next;    // jump to next one and continue.
        else
        {                               // This is the last one, delete it.
            free(theLine->chars);
            free(theLine);
            theLine = NULL;
        }
    }

    // Update the head.
    *listHead           = inLine;
    (*listHead)->prev   = NULL;
}

@end
