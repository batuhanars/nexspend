import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import { join } from 'path';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [
    MulterModule.register({
      dest: join(process.cwd(), 'uploads', 'avatars'),
    }),
  ],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
