//
//  RFPacketHeaders.h
//  Reflect
//
//  Created by Kyle Hickinson on 2012-10-20.
//  Copyright (c) 2012 Kyle Hickinson. All rights reserved.
//

/**
 Packet headers that the server sends to the client.
 */
typedef enum : NSInteger {
    /** 
     Send information about the data that is waiting to send to clients.
     
     Packet structure:
     
        0A [XX XX XX XX XX XX XX XX]
     
        | Size     | Description
     ----------------------------------------------
     0A : uint8_t  : Packet header
     XX : uint64_t : Length of data
     ----------------------------------------------
     
     TODO: Append more data such as type.
     
     */
    RFServerSendingDataInformation = 10,
    
    /**
     Send user a flag marking the beginning of streaming a file to the
     client as well as the first batch of data.
     
     Packet structure:
     
        0B [XX XX ...]
     
        | Size     | Description
     ----------------------------------------------
     XX : x bytes  : A cluster of bytes for the data being sent over.
     */
    RFServerBeginSendingData,
    
    /**
     Tell the client that this server requires a passcode.
     
     
     Packet structure:
        
        0C
     
     This packet doesn't have any extra data.
     */
    RFServerRequiresPasscode,
    
    /**
     Tell the client that the passcode they entered was invalid.
     
     Packet structure:
     
        0D
     
     This packet doesn't have any extra data.
     */
    RFServerReceivedInvalidPasscode
} RFServerPacketHeader;

/**
 Packet headers that the client sends to the server.
 */
typedef enum : NSInteger {
    /**
     Send the server the passcode that allows transmission between each.
     Send length along with the string to prevent buffer overflow/data corruption.
     
     Packet structure:
     
        64 [XX XX XX XX] [YY YY YY ... 00]

        | Size     | Description
     ----------------------------------------------
     64 : uint8_t  : Packet Header
     XX : uint64_t : Length of passcode (minus the null-terminator).
     YY : XX+1     : Passcode data ending in a null-terminator.
     */
    RFClientSendingPasscode = 100,
    
    /**
     Send the server the OK that tells the server to send the client data.
     
     Packet structure:
     
        65
     
     This packet doesn't have any extra data.
     */
    RFClientSendingOK,
    
    /**
     Tell the server that this client is disconnecting.
     
     Packet stucture:
     
        66
     
     This packet doesn't have any extra data.
     */
    RFClientDisconnecting
} RFClientPacketHeader;