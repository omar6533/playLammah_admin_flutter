import { storage } from './firebase';
import { ref, uploadBytes, getDownloadURL, deleteObject } from 'firebase/storage';

export interface UploadResult {
  url: string;
  path: string;
}

export const mediaUtils = {
  async uploadFile(file: File, folder: string = 'general'): Promise<UploadResult> {
    const fileExt = file.name.split('.').pop();
    const fileName = `${folder}/${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;

    const storageRef = ref(storage, fileName);

    await uploadBytes(storageRef, file, {
      contentType: file.type,
      cacheControl: 'public, max-age=3600'
    });

    const url = await getDownloadURL(storageRef);

    return {
      url,
      path: fileName
    };
  },

  async deleteFile(path: string): Promise<void> {
    const storageRef = ref(storage, path);
    await deleteObject(storageRef);
  },

  getPathFromUrl(url: string): string | null {
    try {
      const urlObj = new URL(url);
      const pathMatch = urlObj.pathname.match(/\/o\/(.+)\?/);
      if (pathMatch) {
        return decodeURIComponent(pathMatch[1]);
      }
      return null;
    } catch {
      return null;
    }
  },

  isValidMediaFile(file: File): boolean {
    const validTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/webp',
      'video/mp4',
      'video/webm',
      'video/ogg'
    ];

    return validTypes.includes(file.type);
  },

  getMediaType(file: File): 'image' | 'video' | 'unknown' {
    if (file.type.startsWith('image/')) return 'image';
    if (file.type.startsWith('video/')) return 'video';
    return 'unknown';
  }
};
