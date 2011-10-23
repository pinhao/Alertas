//
//  Shared.h
//  Alertas
//
//  Created by Pedro on 23/10/11.
//  Copyright (c) 2011 System Tech LDA. All rights reserved.
//

#ifndef Alertas_Shared_h
#define Alertas_Shared_h

#ifdef DEBUG
#define DLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... ) 
#endif

#endif
