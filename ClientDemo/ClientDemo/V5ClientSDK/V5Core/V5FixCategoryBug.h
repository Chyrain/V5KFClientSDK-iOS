//
//  FixCategoryBug.h
//  V5KFClientTest
//
//  Created by chyrain on 15/12/30.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#ifndef MainLib_V5FixCategoryBug_h
#define MainLib_V5FixCategoryBug_h

#define __v5kw_to_string_1(x) #x
#define __v5kw_to_string(x)  __v5kw_to_string_1(x)

// 需要在有category的头文件中调用，例如 KW_FIX_CATEGORY_BUG_H(NSString_Extented)
#define V5KW_FIX_CATEGORY_BUG_H(name) \
@interface V5KW_FIX_CATEGORY_BUG_##name : NSObject \
+(void)print; \
@end

// 需要在有category的源文件中调用，例如 KW_FIX_CATEGORY_BUG_M(NSString_Extented)
#define V5KW_FIX_CATEGORY_BUG_M(name) \
@implementation V5KW_FIX_CATEGORY_BUG_##name \
+ (void)print { \
} \
@end \


// 在target中启用这个宏，其实就是调用下category中定义的类的print方法。
#define V5KW_ENABLE_CATEGORY(name) [V5KW_FIX_CATEGORY_BUG_##name print]

#endif
