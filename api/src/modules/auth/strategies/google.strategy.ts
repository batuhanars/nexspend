import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy, VerifyCallback } from 'passport-google-oauth20';
import { ConfigService } from '@nestjs/config';

export interface GoogleProfile {
  id: string;
  email: string;
  fullName: string;
  picture?: string;
}

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(configService: ConfigService) {
    super({
      clientID: configService.get<string>('google.clientId') as string,
      clientSecret: configService.get<string>('google.clientSecret') as string,
      callbackURL: configService.get<string>('google.callbackUrl') as string,
      scope: ['email', 'profile'],
    });
  }

  validate(
    _accessToken: string,
    _refreshToken: string,
    profile: {
      id: string;
      emails: Array<{ value: string }>;
      displayName: string;
      photos?: Array<{ value: string }>;
    },
    done: VerifyCallback,
  ) {
    const googleProfile: GoogleProfile = {
      id: profile.id,
      email: profile.emails[0].value,
      fullName: profile.displayName,
      picture: profile.photos?.[0]?.value,
    };
    done(null, googleProfile);
  }
}
