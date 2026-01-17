import { LogOut, User } from 'lucide-react';

export default function Header() {
  return (
    <header className="bg-white border-b border-gray-200 fixed top-0 right-0 left-64 h-16 flex items-center justify-end px-6 z-10">
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center">
            <User className="w-5 h-5 text-white" />
          </div>
          <div className="text-right">
            <p className="text-sm font-semibold text-gray-900">Admin User</p>
            <p className="text-xs text-gray-500">admin@quizgame.com</p>
          </div>
        </div>

        <button className="ml-4 flex items-center gap-2 px-4 py-2 text-sm font-medium text-gray-700 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors">
          <LogOut className="w-4 h-4" />
          <span>Logout</span>
        </button>
      </div>
    </header>
  );
}
