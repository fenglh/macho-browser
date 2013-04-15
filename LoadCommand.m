//
//  LoadCommand.m
//  Mach-O Browser
//
//  Created by David Schweinsberg on 29/10/09.
//  Copyright 2009 David Schweinsberg. All rights reserved.
//

#import "LoadCommand.h"
#import "SegmentLoadCommand.h"
#import "SymbolTableLoadCommand.h"
#include <mach-o/loader.h>
//#include <mach/i386/thread_status.h>
//#include <mach/arm/thread_status.h>

// struct thread_command has flavor and count commented out.  We only have
// minimal support for this command at the moment.
struct local_thread_command {
	uint32_t	cmd;		/* LC_THREAD or  LC_UNIXTHREAD */
	uint32_t	cmdsize;	/* total size of this command */
	uint32_t flavor;		    /*flavor of thread state */
	uint32_t count;		    /*count of longs in thread state */
	/* struct XXX_thread_state state   thread state for this flavor */
	/* ... */
};

@implementation LoadCommand

@synthesize malformed;

- (id)initWithData:(NSData *)aData offset:(NSUInteger)anOffset
{
    // Trying to be clever with the following code, but it might be better
    // to just use a factory function -- see if this causes confusion

    // Determine if we need to return a subclass
    const unsigned char *bytes = aData.bytes;
    struct load_command *lc = (struct load_command *)(bytes + anOffset);
    uint32_t cmd;
    uint32_t m = *(uint32_t *)bytes;
    if (m == MH_CIGAM || m == MH_CIGAM_64)
        cmd = CFSwapInt32(lc->cmd);
    else
        cmd = lc->cmd;

    if (cmd == LC_SEGMENT || cmd == LC_SEGMENT_64)
    {
        [self release];
        return [[SegmentLoadCommand alloc] initWithData:aData offset:anOffset];
    }
    else if (cmd == LC_SYMTAB)
    {
        [self release];
        return [[SymbolTableLoadCommand alloc] initWithData:aData offset:anOffset];
    }
    
    self = [super init];
    if (self)
    {
        data = aData;
        offset = anOffset;
    }
    return self;
}

#pragma mark -
#pragma mark Properties

- (uint32_t)command
{
    struct load_command *lc = (struct load_command *)(data.bytes + offset);
    if (self.swapBytes)
        return CFSwapInt32(lc->cmd);
    else
        return lc->cmd;
}

- (NSString *)commandName
{
    uint32_t cmd = self.command;
    switch (cmd)
    {
        case LC_SEGMENT:
            return @"LC_SEGMENT";
        case LC_SYMTAB:
            return @"LC_SYMTAB";
        case LC_SYMSEG:
            return @"LC_SYMSEG";
        case LC_THREAD:
            return @"LC_THREAD";
        case LC_UNIXTHREAD:
            return @"LC_UNIXTHREAD";
        case LC_LOADFVMLIB:
            return @"LC_LOADFVMLIB";
        case LC_IDFVMLIB:
            return @"LC_IDFVMLIB";
        case LC_IDENT:
            return @"LC_IDENT";
        case LC_FVMFILE:
            return @"LC_FVMFILE";
        case LC_PREPAGE:
            return @"LC_PREPAGE";
        case LC_DYSYMTAB:
            return @"LC_DYSYMTAB";
        case LC_LOAD_DYLIB:
            return @"LC_LOAD_DYLIB";
        case LC_ID_DYLIB:
            return @"LC_ID_DYLIB";
        case LC_LOAD_DYLINKER:
            return @"LC_LOAD_DYLINKER";
        case LC_ID_DYLINKER:
            return @"LC_ID_DYLINKER";
        case LC_PREBOUND_DYLIB:
            return @"LC_PREBOUND_DYLIB";
        case LC_ROUTINES:
            return @"LC_ROUTINES";
        case LC_SUB_FRAMEWORK:
            return @"LC_SUB_FRAMEWORK";
        case LC_SUB_UMBRELLA:
            return @"LC_SUB_UMBRELLA";
        case LC_SUB_CLIENT:
            return @"LC_SUB_CLIENT";
        case LC_SUB_LIBRARY:
            return @"LC_SUB_LIBRARY";
        case LC_TWOLEVEL_HINTS:
            return @"LC_TWOLEVEL_HINTS";
        case LC_PREBIND_CKSUM:
            return @"LC_PREBIND_CKSUM";
        case LC_LOAD_WEAK_DYLIB:
            return @"LC_LOAD_WEAK_DYLIB";
        case LC_SEGMENT_64:
            return @"LC_SEGMENT_64";
        case LC_ROUTINES_64:
            return @"LC_ROUTINES_64";
        case LC_UUID:
            return @"LC_UUID";
        case LC_RPATH:
            return @"LC_RPATH";
        case LC_CODE_SIGNATURE:
            return @"LC_CODE_SIGNATURE";
        case LC_SEGMENT_SPLIT_INFO:
            return @"LC_SEGMENT_SPLIT_INFO";
        case LC_REEXPORT_DYLIB:
            return @"LC_REEXPORT_DYLIB";
        case LC_LAZY_LOAD_DYLIB:
            return @"LC_LAZY_LOAD_DYLIB";
        case LC_ENCRYPTION_INFO:
            return @"LC_ENCRYPTION_INFO";
        case LC_DYLD_INFO:
            return @"LC_DYLD_INFO";
        case LC_DYLD_INFO_ONLY:
            return @"LC_DYLD_INFO_ONLY";
    }
    return [NSString stringWithFormat:@"0x%x", cmd];
}

- (uint32_t)commandSize
{
    struct load_command *lc = (struct load_command *)(data.bytes + offset);
    if (self.swapBytes)
        return CFSwapInt32(lc->cmdsize);
    else
        return lc->cmdsize;
}

- (NSDictionary *)dictionary
{
    uint32_t cmd = self.command;
    if (cmd == LC_UUID)
    {
        struct uuid_command *c = (struct uuid_command *)(data.bytes + offset);
        NSString *uuidString = [NSString stringWithFormat:
                                @"%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                                c->uuid[0],
                                c->uuid[1],
                                c->uuid[2],
                                c->uuid[3],
                                c->uuid[4],
                                c->uuid[5],
                                c->uuid[6],
                                c->uuid[7],
                                c->uuid[8],
                                c->uuid[9],
                                c->uuid[10],
                                c->uuid[11],
                                c->uuid[12],
                                c->uuid[13],
                                c->uuid[14],
                                c->uuid[15]];
        return [NSDictionary dictionaryWithObjectsAndKeys:uuidString, @"uuid", nil, nil];
    }
/*
    else if (cmd == LC_SYMTAB)
    {
        struct symtab_command *c = (struct symtab_command *)(data.bytes + offset);
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithUnsignedInteger:c->symoff], @"symoff",
                [NSNumber numberWithUnsignedInteger:c->nsyms], @"nsyms",
                [NSNumber numberWithUnsignedInteger:c->stroff], @"stroff",
                [NSNumber numberWithUnsignedInteger:c->strsize], @"strsize",
                nil, nil];
    }
*/
    else if (cmd == LC_DYSYMTAB)
    {
        struct dysymtab_command *c = (struct dysymtab_command *)(data.bytes + offset);
        if (self.swapBytes)
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->ilocalsym)], @"ilocalsym",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->nlocalsym)], @"nlocalsym",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->iextdefsym)], @"iextdefsym",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->nextdefsym)], @"nextdefsym",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->iundefsym)], @"iundefsym",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->nundefsym)], @"nundefsym",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->tocoff)], @"tocoff",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->ntoc)], @"ntoc",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->modtaboff)], @"modtaboff",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->nmodtab)], @"nmodtab",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->extrefsymoff)], @"extrefsymoff",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->nextrefsyms)], @"nextrefsyms",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->indirectsymoff)], @"indirectsymoff",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->nindirectsyms)], @"nindirectsyms",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->extreloff)], @"extreloff",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->nextrel)], @"nextrel",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->locreloff)], @"locreloff",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->nlocrel)], @"nlocrel",
                    nil, nil];
        else
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithUnsignedInteger:c->ilocalsym], @"ilocalsym",
                    [NSNumber numberWithUnsignedInteger:c->nlocalsym], @"nlocalsym",
                    [NSNumber numberWithUnsignedInteger:c->iextdefsym], @"iextdefsym",
                    [NSNumber numberWithUnsignedInteger:c->nextdefsym], @"nextdefsym",
                    [NSNumber numberWithUnsignedInteger:c->iundefsym], @"iundefsym",
                    [NSNumber numberWithUnsignedInteger:c->nundefsym], @"nundefsym",
                    [NSNumber numberWithUnsignedInteger:c->tocoff], @"tocoff",
                    [NSNumber numberWithUnsignedInteger:c->ntoc], @"ntoc",
                    [NSNumber numberWithUnsignedInteger:c->modtaboff], @"modtaboff",
                    [NSNumber numberWithUnsignedInteger:c->nmodtab], @"nmodtab",
                    [NSNumber numberWithUnsignedInteger:c->extrefsymoff], @"extrefsymoff",
                    [NSNumber numberWithUnsignedInteger:c->nextrefsyms], @"nextrefsyms",
                    [NSNumber numberWithUnsignedInteger:c->indirectsymoff], @"indirectsymoff",
                    [NSNumber numberWithUnsignedInteger:c->nindirectsyms], @"nindirectsyms",
                    [NSNumber numberWithUnsignedInteger:c->extreloff], @"extreloff",
                    [NSNumber numberWithUnsignedInteger:c->nextrel], @"nextrel",
                    [NSNumber numberWithUnsignedInteger:c->locreloff], @"locreloff",
                    [NSNumber numberWithUnsignedInteger:c->nlocrel], @"nlocrel",
                    nil, nil];
    }
    else if (cmd == LC_LOAD_DYLIB
             || cmd == LC_LOAD_WEAK_DYLIB
             || cmd == LC_ID_DYLIB)
    {
        struct dylib_command *c = (struct dylib_command *)(data.bytes + offset);
        NSString *nameString;
        NSDate *timestampDate;
        NSString *currentVersionString;
        NSString *compatibilityVersionString;
        if (self.swapBytes)
        {
            nameString = [NSString stringWithFormat:@"%s", data.bytes + offset + CFSwapInt32(c->dylib.name.offset)];
            timestampDate = [NSDate dateWithTimeIntervalSince1970:CFSwapInt32(c->dylib.timestamp)];
            currentVersionString = [NSString stringWithFormat:
                                    @"%d.%d.%d",
                                    CFSwapInt32(c->dylib.current_version) >> 16,
                                    (CFSwapInt32(c->dylib.current_version) >> 8) & 0xff,
                                    CFSwapInt32(c->dylib.current_version) & 0xff];
            compatibilityVersionString = [NSString stringWithFormat:
                                          @"%d.%d.%d",
                                          CFSwapInt32(c->dylib.compatibility_version) >> 16,
                                          (CFSwapInt32(c->dylib.compatibility_version) >> 8) & 0xff,
                                          CFSwapInt32(c->dylib.compatibility_version) & 0xff];
        }
        else
        {
            nameString = [NSString stringWithFormat:@"%s", data.bytes + offset + c->dylib.name.offset];
            timestampDate = [NSDate dateWithTimeIntervalSince1970:c->dylib.timestamp];
            currentVersionString = [NSString stringWithFormat:
                                    @"%d.%d.%d",
                                    c->dylib.current_version >> 16,
                                    (c->dylib.current_version >> 8) & 0xff,
                                    c->dylib.current_version & 0xff];
            compatibilityVersionString = [NSString stringWithFormat:
                                          @"%d.%d.%d",
                                          c->dylib.compatibility_version >> 16,
                                          (c->dylib.compatibility_version >> 8) & 0xff,
                                          c->dylib.compatibility_version & 0xff];
        }
        return [NSDictionary dictionaryWithObjectsAndKeys:
                nameString, @"name",
                timestampDate.description, @"timestamp",
                currentVersionString, @"current version",
                compatibilityVersionString, @"compatibility version",
                nil, nil];
    }
    else if (cmd == LC_LOAD_DYLINKER || cmd == LC_ID_DYLINKER)
    {
        struct dylinker_command *c = (struct dylinker_command *)(data.bytes + offset);
        NSString *nameString;
        if (self.swapBytes)
            nameString = [NSString stringWithFormat:@"%s", data.bytes + offset + CFSwapInt32(c->name.offset)];
        else
            nameString = [NSString stringWithFormat:@"%s", data.bytes + offset + c->name.offset];
        return [NSDictionary dictionaryWithObjectsAndKeys:
                nameString, @"name",
                nil, nil];
    }
    else if (cmd == LC_THREAD || cmd == LC_UNIXTHREAD)
    {
        struct local_thread_command *c = (struct local_thread_command *)(data.bytes + offset);
        if (self.swapBytes)
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->flavor)], @"flavor",
                    [NSNumber numberWithUnsignedInteger:CFSwapInt32(c->count)], @"count",
                    nil, nil];
        else
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithUnsignedInteger:c->flavor], @"flavor",
                    [NSNumber numberWithUnsignedInteger:c->count], @"count",
                    nil, nil];
    }
    return nil;
}

- (BOOL)swapBytes
{
    uint32_t m = *(uint32_t *)data.bytes;
    if (m == MH_CIGAM || m == MH_CIGAM_64)
        return YES;
    else
        return NO;
}

- (BOOL)dataAvailable
{
    // Is the load command supported yet?
    // dataAvailable returns NO if unsupported.
    uint32_t cmd = self.command;
    switch (cmd)
    {
        case LC_SEGMENT:
        case LC_SYMTAB:
        //case LC_SYMSEG:
        //case LC_THREAD:
        //case LC_UNIXTHREAD:
        //case LC_LOADFVMLIB:
        //case LC_IDFVMLIB:
        //case LC_IDENT:
        //case LC_FVMFILE:
        //case LC_PREPAGE:
        case LC_DYSYMTAB:
        case LC_LOAD_DYLIB:
        case LC_ID_DYLIB:
        case LC_LOAD_DYLINKER:
        case LC_ID_DYLINKER:
        //case LC_PREBOUND_DYLIB:
        //case LC_ROUTINES:
        //case LC_SUB_FRAMEWORK:
        //case LC_SUB_UMBRELLA:
        //case LC_SUB_CLIENT:
        //case LC_SUB_LIBRARY:
        //case LC_TWOLEVEL_HINTS:
        //case LC_PREBIND_CKSUM:
        case LC_LOAD_WEAK_DYLIB:
        case LC_SEGMENT_64:
        //case LC_ROUTINES_64:
        case LC_UUID:
        //case LC_RPATH:
        //case LC_CODE_SIGNATURE:
        //case LC_SEGMENT_SPLIT_INFO:
        //case LC_REEXPORT_DYLIB:
        //case LC_LAZY_LOAD_DYLIB:
        //case LC_ENCRYPTION_INFO:
        //case LC_DYLD_INFO:
        //case LC_DYLD_INFO_ONLY:
            return YES;
    }
    return NO;
}

@end