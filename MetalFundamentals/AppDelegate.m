//
//  AppDelegate.m
//  MetalFundamentals
//
//  Created by Einar Risholm on 21/01/2019.
//  Copyright © 2019 Longship. All rights reserved.
//

#import "AppDelegate.h"

@import Metal;

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate {
    id<MTLCommandQueue> _commandQueue;
    id<MTLDevice> _device;
    id<MTLRenderPipelineState> _pipelineState;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    CGRect rect = CGRectMake(0, 0, 400, 400);
    _device = MTLCreateSystemDefaultDevice();
    MTKView *view = [[MTKView alloc] initWithFrame:rect device:_device];
    view.delegate = self;
    self.window.contentView = view;
    
    _commandQueue = [_device newCommandQueue];
    NSString *shaders =
    @"#include <metal_stdlib>\n"
    "using namespace metal;\n"
    "struct VertexIn {\n"
        "packed_float3 position;\n"
        "packed_float3 color;\n"
    "};\n"
    "struct VertexOut {\n"
        "float4 position [[position]];\n"
        "float4 color;\n"
    "};\n"
    "vertex VertexOut vertex_main(device const VertexIn *vertices [[buffer(0)]],\n"
                                 "uint vertexId [[vertex_id]]) {\n"
        "VertexOut out;\n"
        "out.position = float4(vertices[vertexId].position, 1);\n"
        "out.color = float4(vertices[vertexId].color, 1);\n"
        "return out;\n"
    "}\n"
    "fragment float4 fragment_main(VertexOut in [[stage_in]]) {\n"
        "return in.color;\n"
    "}\n";
    
    id<MTLLibrary> defaultLibrary = [_device newLibraryWithSource:shaders options:nil error:nil];
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = [defaultLibrary newFunctionWithName:@"vertex_main"];
    pipelineStateDescriptor.fragmentFunction = [defaultLibrary newFunctionWithName:@"fragment_main"];
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    
    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    
    if (!_pipelineState) {
        NSLog(@"Failed to created pipeline state, error %@", error);
    };
    
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    
    // Create a new command buffer for each render pass to the current drawable
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // Obtain a renderPassDescriptor generated from the view's drawable textures
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    if(renderPassDescriptor != nil)
    {
        // Create a render command encoder so we can render into something
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        float vertexData[18] = {-0.5, -0.5 , 0.0, 1.0, 0.0, 0.0,
            0.5, -0.5 , 0.0, 0.0, 1.0, 0.0,
            0.0,  0.5 , 0.0, 0.0, 0.0, 1.0
        };
        
        [renderEncoder setVertexBytes:&vertexData
                               length:sizeof(vertexData)
                              atIndex:0];
        
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
        [renderEncoder endEncoding];
        
        // Schedule a present once the framebuffer is complete using the current drawable
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
