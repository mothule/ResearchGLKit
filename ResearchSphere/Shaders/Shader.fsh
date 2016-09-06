//
//  Shader.fsh
//  ResearchSphere
//
//  Created by 川上 基樹 on 2016/09/06.
//  Copyright © 2016年 mothule. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
